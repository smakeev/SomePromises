//
//  SomePromiseChainMethodsExecutorStrategy.m
//  SomePromises
//
//  Created by Sergey Makeev on 25/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseChainMethodsExecutorStrategy.h"
#import "SomePromise.h"
#import "SomePromiseThread.h"
#import "SomePromiseTypes.h"
#import "SomePromiseInternals.h"
#import "SomePromiseUtils.h"

BLOCK_SIGNATURE_AVAILABLE

@interface SomePromise(friend)

- (void) addProvider:(id)provider;

 + (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegateThread
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
									class:(Class _Nullable)class;

 + (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable) delegateQueue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
									class:(Class _Nullable)class;

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegateThread
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
								    class:(Class _Nullable)class;

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
								    class:(Class _Nullable)class;
@end


static void parseBlockParams(NSMethodSignature *blockSignature,
                                                  Class *class,
											   NSString **name,
									   dispatch_queue_t *queue,
									SomePromiseThread **thread,
						   SomeResultProvider **resultProvider,
                  SomeProgressBlockProvider **progressProvider,
              SomeIsRejectedBlockProvider **isRejectedProvider,
                         SomePromiseDelegateWrapper **delegate,
							   dispatch_queue_t *delegateQueue,
                            SomePromiseThread **delegateThread,
		        SomePromiseSettingsObserverWrapper **observers,
		            SomeValuesInChainProvider **valuesProvider,
								   NSMutableArray **parameters,
											      va_list args)
{
		const NSUInteger nargs = blockSignature.numberOfArguments - 1;
		for(NSUInteger i = 0; i < nargs ; ++i)
		{
		    const char* argType = [blockSignature getArgumentTypeAtIndex:i + 1];
			if (strcmp(argType, @encode(Class)) == 0 )
            {
		       *class = va_arg(args, Class);
            } else if (argType[0] == '@')
            {
			   id arg = va_arg(args, id);
			   if([arg isKindOfClass:[NSString class]])
			   {
			      *name = (NSString*)arg;
			   } else if([arg isKindOfClass:[SomePromiseThread class]])
			   {
			     *thread = (SomePromiseThread*)arg;
			   } else if([arg isKindOfClass:[SomePromiseSettingsPromiseWorker class]])
			   {
				   SomePromiseSettingsPromiseWorker *worker = (SomePromiseSettingsPromiseWorker*)arg;
				   *thread = worker.thread;
				   *queue = worker.queue;
			   } else if([arg isKindOfClass:[SomePromiseSettingsPromiseDelegateWorker class]])
			   {
			       SomePromiseSettingsPromiseDelegateWorker *worker = (SomePromiseSettingsPromiseDelegateWorker*)arg;
				   *delegateThread = worker.thread;
				   *delegateQueue = worker.queue;
			   } else if([arg isKindOfClass:[SomePromiseDelegateWrapper class]])
			   {
			       *delegate = ((SomePromiseDelegateWrapper*)arg).delegate;
			   } else if([arg conformsToProtocol:@protocol(SomePromiseDelegate)])
			   {
			       *delegate = [[SomePromiseDelegateWrapper alloc] init];
			       (*delegate).delegate = arg;
			   } else if([arg isKindOfClass:[SomePromiseDelegateWrapper class]])
			   {
			       *delegate = arg;
			   } else if([arg isKindOfClass:[SomePromiseSettingsObserverWrapper class]])
			   {
				   *observers = (SomePromiseSettingsObserverWrapper*)arg;
			   } else if([arg isKindOfClass:[SomeProgressBlockProvider class]])
			   {
				   *progressProvider = (SomeProgressBlockProvider*)arg;
			   } else if([arg isKindOfClass:[SomeIsRejectedBlockProvider class]])
			   {
			       *isRejectedProvider = (SomeIsRejectedBlockProvider*)arg;
			   } else if([arg isKindOfClass:[SomeResultProvider class]])
			   {
			       *resultProvider = (SomeResultProvider*)arg;
			   } else if([arg isKindOfClass:[SomeValuesInChainProvider class]])
			   {
				   *valuesProvider = (SomeValuesInChainProvider*)arg;
			   } else if([arg isKindOfClass:[SomeParameterProvider class]])
			   {
			   		if (*parameters == nil)
			   		{
			   			*parameters = [NSMutableArray new];
					}
					[*parameters addObject:arg];
			   } else if([arg isKindOfClass:([NSObject<OS_dispatch_queue> class])]) //this should be last
			   {
			       *queue = arg;
			   }
			}
			else
	        {
		       FATAL_ERROR(@"wrong parameter", @"Promise block does not support one or more of it's parameters")
			}
		}
}

static void finalizePromise(SomePromise *resultPromise, SomePromiseSettingsObserverWrapper *observers, Class class, NSString *name, dispatch_queue_t queue, SomePromiseThread *thread, id delegate, dispatch_queue_t delegateQueue, SomePromiseThread *delegateThread, SomeResultProvider *resultProvider, SomeProgressBlockProvider *progressProvider, SomeIsRejectedBlockProvider *isRejectedProvider, SomeValuesInChainProvider *valuesProvider)
{
	    //add observers
		if (observers && observers.observers.count)
		{
		    for (id<SomePromiseObserver> observer in observers.observers)
		    {
			    ObserverAsyncWayWrapper *wrapper = [observers.observers objectForKey:observer];
				if(wrapper.queue)
				{
				  [resultPromise addObserver:observer onQueue:wrapper.queue];
				} else if(wrapper.thread)
				{
					[resultPromise addObserver:observer onThread:wrapper.thread];
				} else
				{
					[resultPromise addObserver:observer];
				}
			}
		}
	
		//add providers.
		if(name) [resultPromise addProvider:name];
		if(class) [resultPromise addProvider:class];
        if(queue) [resultPromise addProvider:queue];
        if(thread) [resultPromise addProvider:thread];
        if(resultProvider) [resultPromise addProvider:resultProvider];
        if(progressProvider) [resultPromise addProvider:progressProvider];
        if(isRejectedProvider) [resultPromise addProvider:isRejectedProvider];
        if(delegate) [resultPromise addProvider:delegate];
        if(delegateQueue) [resultPromise addProvider:delegateQueue];
        if(delegateThread) [resultPromise addProvider:delegateThread];
		if(observers) [resultPromise addProvider:observers];
		if(valuesProvider) [resultPromise addProvider:valuesProvider];
}

typedef void (^PromiseBlock)(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain);

static PromiseBlock promiseBlock(SomeValuesInChainProvider *valuesProvider, SomeIsRejectedBlockProvider *isRejectedProvider, SomeProgressBlockProvider *progressProvider, SomeResultProvider *resultProvider, NSInvocation *blockInvocation, NSArray *parameters, const char rtype)
{
	return ^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, NSError *error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
		{
		     @try{
				if(valuesProvider)
				{
				   valuesProvider.chain = lastValuesInChain;
				}
				
				if(isRejectedProvider)
				{
				   isRejectedProvider.isRejectedBlock = isRejectedBlock;
				}
				
				if(progressProvider)
				{
				   progressProvider.progressBlock = progressBlock;
				}
				
				if(resultProvider)
				{
					resultProvider.finished = YES;
					resultProvider.result = result;
					resultProvider.error = error;
				}
				
				if(parameters)
				{
					//do nothing, just need to store parameters
				}
				
		        [blockInvocation invoke];
		     }
			 @catch(NSException *exception){
		        rejectBlock([SomePromiseUtils errorFromException:exception]);
		        return;
	         }
	         @catch(NSError *error){
		        rejectBlock(error);
		        return;
	         }
	         @catch(...){
		        rejectBlock(rejectionErrorWithText(@"Unknown Exception", ESomePromiseError_FromException));
		        return;
	         }
			
	         switch (rtype)
             {
                case 'v':
                   fulfillBlock(Void);
                   return;
				case '@':
		        {
			        __weak id block_result = nil;
			        [blockInvocation getReturnValue:&block_result];
			        if (!block_result || [block_result isKindOfClass:[NSError class]])
			        {
			           rejectBlock(block_result);
			           return;
				    }
				    fulfillBlock(block_result);
				    return;
		         }
		         default:
		         {
			        id block_result = nil;
			        if(strcmp(&rtype, @encode(double)) == 0 ||  rtype == 'd')
			        {
			           double result = 0.0;
				       [blockInvocation getReturnValue:&result];
				       block_result = [NSNumber numberWithDouble:result];
			        }
                    else if(strcmp(&rtype, @encode(float)) == 0 || rtype == 'f')
                    {
				       float result = 0.0f;
				       [blockInvocation getReturnValue:&result];
				       block_result = [NSNumber numberWithFloat:result];
			        }
                    else if(strcmp(&rtype, @encode(unsigned long)) == 0 || rtype == 'Q')
                    {
				       unsigned long result = 0.0f;
				       [blockInvocation getReturnValue:&result];
				       block_result = [NSNumber numberWithUnsignedLong:result];
			         }
			         else if(strcmp(&rtype, @encode(unsigned long long)) == 0)
			         {
				        unsigned long long result = 0.0f;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithUnsignedLongLong:result];
			         }
			         else if(strcmp(&rtype, @encode(long)) == 0 || rtype == 'q')
			         {
				        long result = 0.0f;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithLong:result];
			         }
			         else if(strcmp(&rtype, @encode(long long)) == 0)
			         {
						long long result = 0.0f;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithLongLong:result];
			         }
			         else if(strcmp(&rtype, @encode(int)) == 0  || rtype == 'i')
			         {
				        int result = 0;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithInt:result];
			         }
				     else if(strcmp(&rtype, @encode(unsigned int)) == 0 || rtype == 'I')
			         {
				        unsigned int result = 0;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithUnsignedInt:result];
			         }
			         else if(strcmp(&rtype, @encode(BOOL)) == 0 || strcmp(&rtype, @encode(bool)) == 0 || rtype == 'B')
			         {
				        BOOL result = NO;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithBool:result];
			         }
			         else if(strcmp(&rtype, @encode(char)) == 0 || rtype == 'c')
			         {
				        char result = 0;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithChar:result];
			         }
			         else if(strcmp(&rtype, @encode(unsigned char)) == 0 || rtype == 'C')
			         {
				        unsigned char result = 0;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithUnsignedChar:result];
			         }
			         else if(strcmp(&rtype, @encode(short)) == 0 || rtype == 's')
					 {
				        short result = 0;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithShort:result];
			         }
			         else if(strcmp(&rtype, @encode(unsigned short)) == 0 || rtype == 'S')
                     {
				        unsigned short result = 0;
				        [blockInvocation getReturnValue:&result];
				        block_result = [NSNumber numberWithUnsignedShort:result];
			         }
			         else if (rtype == 'r' ||
			                  rtype == '*' ||
			                  rtype == '^' ||
			                  strcmp(&rtype, @encode(char *)) == 0 ||
			                  rtype == '?' ) //pointer ( and const pointer)
			         {
						void *result = NULL;
				        [blockInvocation getReturnValue:&result];
				        if(result == NULL)
				        {
				           rejectBlock(nil);
				           return;
				        }
				        block_result = [NSValue valueWithPointer:result];
			         }
			         else
			         {
			            FATAL_ERROR(@"unsupported return type", @"Promise block's return type is unsupported.")
			         }
			         fulfillBlock(block_result);
		           }
				}
		};
}

@interface SomePromiseChainMethodsExecutorStrategy ()

@end 

@implementation SomePromiseChainMethodsExecutorStrategy
@dynamic chain;
@dynamic delegateThread;
@dynamic name;
@dynamic delegate;
@dynamic delegatePromiseQueue;
@dynamic status;

- (void) privateAddWhen:(id<WhenPromiseProtocol>) when
{
   [self doesNotRecognizeSelector:_cmd];
}

- (id _Nullable)getFuture
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (void) privateAddToDependancy:(id<DependentPromiseProtocol>) dependee
{
   [self doesNotRecognizeSelector:_cmd];
}

- (SomePromise*) thenExecute:(FutureBlock) body class:(Class _Nullable)class
{
   return [self thenOnQueue: nil execute: body elseExecute: nil class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
   return [self thenWithName: name onQueue: nil execute: body elseExecute: nil class: class];
}

- (SomePromise*) thenOnQueue:(dispatch_queue_t) queue execute:(FutureBlock) body class:(Class _Nullable)class
{
   return [self thenOnQueue: queue execute: body elseExecute: nil class: class];
}

- (SomePromise *_Nonnull) thenOnThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
   return [self thenOnThread: thread execute: body elseExecute: nil class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self thenWithName: name onQueue: queue execute: body elseExecute: nil class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
   return [self thenWithName: name onThread: thread execute: body elseExecute: nil class: class];
}

- (SomePromise*) thenOnMainExecute:(FutureBlock) body class:(Class _Nullable)class
{
   return [self thenOnQueue: dispatch_get_main_queue() execute: body elseExecute: nil class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self thenWithName: name onQueue: dispatch_get_main_queue() execute: body elseExecute: nil class: class];
}

- (SomePromise*) thenExecute:(FutureBlock) body elseExecute:(NoFutureBlock) elseBody class:(Class _Nullable)class
{
   return [self thenOnQueue: nil execute: body elseExecute: elseBody class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull ) body elseExecute:(NoFutureBlock _Nonnull) elseBody class:(Class _Nullable)class
{
     return [self thenWithName: name onQueue: nil execute: body elseExecute: elseBody class: class];
}

- (SomePromise*) thenOnMainExecute:(FutureBlock) body elseOnMainExecute:(NoFutureBlock) elseBody class:(Class _Nullable)class
{
   return [self thenOnQueue: dispatch_get_main_queue() execute: body elseExecute: elseBody class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull ) body elseOnMainExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class
{
   return [self thenWithName: name onQueue: dispatch_get_main_queue() execute: body elseExecute: elseBody class: class];
}

- (SomePromise*) thenOnQueue: (dispatch_queue_t) queue execute:(FutureBlock) body elseExecute:(NoFutureBlock) elseBody class:(Class _Nullable)class
{
   return [self thenWithName: nil onQueue: queue execute: body elseExecute: elseBody class: class];
}

- (SomePromise *_Nonnull) thenOnThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class
{
   return [self thenWithName: nil onThread: thread execute: body elseExecute: elseBody class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class
{
	FutureBlock thenBlock = [body copy];
	NoFutureBlock elseBlock = elseBody ? [elseBody copy] : nil;
    _InternalChainHandler *chain = self.chain;
	if(self.delegateThread)
    {
	     return [SomePromise promiseWithName: name ? name : self.name
								 dependentOn: self
								     onQueue: queue
							        delegate: self.delegate
							  delegateThread: self.delegateThread
							       onSuccess: ^(ThenParams)
			                       {
				                      thenBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
			                       }
							        onReject: ^(ElseParams)
			                        {
				                        if (elseBlock)
				                        {
					                        elseBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, chain);
				                        }
				                        else
				                        {
					                        rejectBlock(error);
				                        }
			                        }
			                        class: class];
	}
	
    return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
								onQueue: queue
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
								 thenBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
							  }
							   onReject: ^(ElseParams)
							   {
								  if (elseBlock)
								  {
									elseBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, chain);
								  }
								  else
								  {
									 rejectBlock(error);
								  }
							   }
							   class: class];
}

- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class
{
	FutureBlock thenBlock = [body copy];
	NoFutureBlock elseBlock = elseBody ? [elseBody copy] : nil;
    _InternalChainHandler *chain = self.chain;
    if(self.delegateThread)
    {
	    return [SomePromise promiseWithName: name ? name : self.name
		     					dependentOn: self
			    				   onThread: thread
				    			   delegate: self.delegate
					    	 delegateThread: self.delegateThread
						    	  onSuccess: ^(ThenParams)
			                      {
				                      thenBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
			                      }
								  onReject: ^(ElseParams)
			                      {
				                      if (elseBlock)
				                      {
					                     elseBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, chain);
									  }
				                      else
				                      {
					                     rejectBlock(error);
				                      }
			                     }
			                     class: class];
	}
	
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
							   onThread: thread
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
								 thenBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
							  }
							   onReject: ^(ElseParams)
							   {
				                      if (elseBlock)
				                      {
					                     elseBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, chain);
									  }
				                      else
				                      {
					                     rejectBlock(error);
				                      }
							  }
							  class: class];
}

//-----------------------

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self after: interval onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self after: interval  withName: name onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self after: interval  withName: nil onQueue: queue execute: body class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
    return [self after: interval  withName: nil onThread: thread execute: body class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval  withName:(NSString *_Nullable) name onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    FutureBlock afterBlock = [body copy];
	_InternalChainHandler *chain = self.chain;
	
	if(self.delegateThread)
	{
	    return [SomePromise promiseWithName: name ? name : self.name
		    					dependentOn: self
					    			onQueue: queue
						    	   delegate: self.delegate
							 delegateThread: self.delegateThread
							      onSuccess: ^(ThenParams)
							      {
										dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
										                             (int64_t)(interval * NSEC_PER_SEC)),
														queue ? queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
								        {
								            afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
								        });
							      }
							       onReject: ^(ElseParams)
							       {
								      rejectBlock(error);
							       }
							       class: class];
	}
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
								onQueue: queue
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {							      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), queue ? queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
								  {
								     afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
								  });
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
    FutureBlock afterBlock = [body copy];
	_InternalChainHandler *chain = self.chain;

	if(self.delegateThread)
	{
	    return [SomePromise promiseWithName: name ? name : self.name
		    					dependentOn: self
								   onThread: thread
						    	   delegate: self.delegate
							 delegateThread: self.delegateThread
							      onSuccess: ^(ThenParams)
							      {
                                        [thread performBlock:^{
                                                 afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
                                               } afterDelay:interval];
							      }
							       onReject: ^(ElseParams)
							       {
								      rejectBlock(error);
							       }
							       class: class];
	}
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
							   onThread: thread
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
							      [thread performBlock:^{
								           afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, chain);
								          } afterDelay:interval];
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self after: interval onQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self after: interval  withName: name onQueue: dispatch_get_main_queue() execute: body class: class];
}

//------------------------

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self afterPromise: promise onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self afterPromise: promise withName: name onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self afterPromise: promise onQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self afterPromise: promise withName: name onQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    return [self afterPromise: promise withName: nil onQueue: queue execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
    return [self afterPromise: promise withName: nil onThread: thread execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    FutureBlock afterBlock = [body copy];
	_InternalChainHandler *chain = self.chain;
	
	if(self.delegateThread)
	{
	      return [SomePromise promiseWithName: name ? name : self.name
								  dependentOn: self
								      onQueue: queue
							         delegate: self.delegate
						       delegateThread: self.delegateThread
							        onSuccess: ^(ThenParams)
							        {
                                       id upPromiseResult = result;
								       [[[[SomePromise promiseWithName: @"Sub-Promise"
														   dependentOn: promise
														       onQueue: queue
														      delegate: nil
													     delegateQueue: nil
														     onSuccess: ^(ThenParams)
									                         {
										                        afterBlock(fulfillBlock,
																			rejectBlock,
																		isRejectedBlock,
													                      progressBlock,
																		upPromiseResult,
													                             chain);
									                         }
														     onReject: ^(ElseParams)
									                         {
										                       afterBlock(fulfillBlock,
										                                   rejectBlock,
												                       isRejectedBlock,
												                         progressBlock,
												                       upPromiseResult,
												                                chain);
									                          }
														      onChain:chain
														      class: class] onProgress:^(float progress)
									                          {
										                            progressBlock(progress);
									                          }] onReject:^(NSError *error)
									                          {
										                         rejectBlock(error);
									                          }] onSuccess:^(AnyResult(result))
								                              {
									                             fulfillBlock(result);
								                              }];
									}
							        onReject: ^(ElseParams)
							        {
								       rejectBlock(error);
							        }
							        class: class];
	}
	
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
								onQueue: queue
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
                                   id upPromiseResult = result;
								  [[[[SomePromise promiseWithName: @"Sub-Promise"
													  dependentOn: promise
														  onQueue: queue
														 delegate: nil
													delegateQueue: nil
														onSuccess: ^(ThenParams)
									  {
										   afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
									  }
														 onReject: ^(ElseParams)
									  {
										 
										  afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
									  }
														  onChain:nil
														  class: class] onProgress:^(float progress)
									 {
										 progressBlock(progress);
									 }] onReject:^(NSError *error)
									{
										rejectBlock(error);
									}] onSuccess:^(AnyResult(result))
								   {
									   fulfillBlock(result);
								   }];
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
}

- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
    FutureBlock afterBlock = [body copy];
	_InternalChainHandler *chain = self.chain;
	
	if(self.delegateThread)
	{
	      return [SomePromise promiseWithName: name ? name : self.name
								  dependentOn: self
									 onThread: thread
							         delegate: self.delegate
						       delegateThread: self.delegateThread
							        onSuccess: ^(ThenParams)
							        {
                                       id upPromiseResult = result;
								       [[[[SomePromise promiseWithName: @"Sub-Promise"
														   dependentOn: promise
															  onThread: thread
														      delegate: nil
													     delegateQueue: nil
														     onSuccess: ^(ThenParams)
									                         {
										                        afterBlock(fulfillBlock,
																			rejectBlock,
																		isRejectedBlock,
													                      progressBlock,
																		upPromiseResult,
													                             chain);
									                         }
														     onReject: ^(ElseParams)
									                         {
										                       afterBlock(fulfillBlock,
										                                   rejectBlock,
												                       isRejectedBlock,
												                         progressBlock,
												                       upPromiseResult,
												                                chain);
									                          }
														      onChain:chain
														      class: class] onProgress:^(float progress)
									                          {
										                            progressBlock(progress);
									                          }] onReject:^(NSError *error)
									                          {
										                         rejectBlock(error);
									                          }] onSuccess:^(AnyResult(result))
								                              {
									                             fulfillBlock(result);
								                              }];
									}
							        onReject: ^(ElseParams)
							        {
								       rejectBlock(error);
							        }
							        class: class];
	}
	
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
							   onThread: thread
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
                                   id upPromiseResult = result;
								  [[[[SomePromise promiseWithName: @"Sub-Promise"
													  dependentOn: promise
														 onThread: thread
														 delegate: nil
													delegateQueue: nil
														onSuccess: ^(ThenParams)
									  {
										   afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
									  }
														 onReject: ^(ElseParams)
									  {
										 
										  afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
									  }
														  onChain:chain
														  class: class] onProgress:^(float progress)
									 {
										 progressBlock(progress);
									 }] onReject:^(NSError *error)
									{
										rejectBlock(error);
									}] onSuccess:^(AnyResult(result))
								   {
									   fulfillBlock(result);
								   }];
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self afterPromises: promises onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self afterPromises: promises withName: name onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self afterPromises: promises onQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self afterPromises: promises withName: name onQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
   return [self afterPromises: promises withName: nil onQueue: queue execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
   return [self afterPromises: promises withName: nil onThread: thread execute: body class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises  withName:(NSString *_Nullable) name onQueue: (dispatch_queue_t _Nullable ) queue execute:(FutureBlock _Nonnull ) body class:(Class _Nullable)class
{
    FutureBlock afterBlock = [body copy];
	_InternalChainHandler *chain = self.chain;
	
	if(self.delegateThread)
	{
	     return [SomePromise promiseWithName: name ? name : self.name
							     dependentOn: self
								     onQueue: queue
							        delegate: self.delegate
						      delegateThread: self.delegateThread
							       onSuccess: ^(ThenParams)
							       {
							           id upPromiseResult = result;
								       if(promises.count == 0)
								       {
									      afterBlock(fulfillBlock,
									                  rejectBlock,
												  isRejectedBlock,
													progressBlock,
												  upPromiseResult,
												           chain);
									      return;
									   }
								  
								       __block NSInteger promisesCount = promises.count;
								       dispatch_queue_t sync_queue = dispatch_queue_create("afterPromisesSyncQueue", DISPATCH_QUEUE_SERIAL);
								  
								       for (SomePromise *promise in promises)
								       {
									       [[SomePromise promiseWithName: [NSString stringWithFormat:@"Sub-Promise(%@)", name]
														     dependentOn: promise
															     onQueue: queue
														        delegate: nil
													       delegateQueue: nil
														       onSuccess: ^(ThenParams)
										                       {
											                      fulfillBlock(Void);
										                       }
														       onReject: ^(ElseParams)
										                       {
											                      fulfillBlock(Void);
										                       }
															   onChain:nil
															   class: class] onSuccess:^(NoResult)
									                           {
										                          __block BOOL shouldRunBlock = NO;
										                          dispatch_sync(sync_queue, ^
														          {
															          promisesCount -= 1;
															          if(promisesCount == 0)
															          {
																        shouldRunBlock = YES;
															          }
														          });
											
										                          if(shouldRunBlock)
										                          {
											                         afterBlock(fulfillBlock,
											                                     rejectBlock,
																			 isRejectedBlock,
																			   progressBlock,
																			 upPromiseResult,
																			          chain);
										                          }
									                           }];
								  }
								  
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
	}
	
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
								onQueue: queue
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
							      id upPromiseResult = result;
								  if(promises.count == 0)
								  {
									  afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
									  return;
								  }
								  
								  __block NSInteger promisesCount = promises.count;
								  dispatch_queue_t sync_queue = dispatch_queue_create("afterPromisesSyncQueue", DISPATCH_QUEUE_SERIAL);
								  
								  for (SomePromise *promise in promises)
								  {
									  [[SomePromise promiseWithName: [NSString stringWithFormat:@"Sub-Promise(%@)", name]
														dependentOn: promise
															onQueue: queue
														   delegate: nil
													  delegateQueue: nil
														  onSuccess: ^(ThenParams)
										{
											fulfillBlock(Void);
										}
														   onReject: ^(ElseParams)
										{
											fulfillBlock(Void);
										}
															onChain:nil
															  class: class]
										onSuccess:^(NoResult)
									    {
										   __block BOOL shouldRunBlock = NO;
										   dispatch_sync(sync_queue, ^
										   {
												promisesCount -= 1;
												if(promisesCount == 0)
												{
													shouldRunBlock = YES;
												}
										   });
										   if(shouldRunBlock)
										   {
											   afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
										   }
									     }];
								  }
								  
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
}

- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class
{
    FutureBlock afterBlock = [body copy];
	_InternalChainHandler *chain = self.chain;
	
	if(self.delegateThread)
	{
	     return [SomePromise promiseWithName: name ? name : self.name
							     dependentOn: self
									onThread: thread
							        delegate: self.delegate
						      delegateThread: self.delegateThread
							       onSuccess: ^(ThenParams)
							       {
							           id upPromiseResult = result;
								       if(promises.count == 0)
								       {
									      afterBlock(fulfillBlock,
									                  rejectBlock,
												  isRejectedBlock,
													progressBlock,
												  upPromiseResult,
												           chain);
									      return;
									   }
								  
								       __block NSInteger promisesCount = promises.count;
								       dispatch_queue_t sync_queue = dispatch_queue_create("afterPromisesSyncQueue", DISPATCH_QUEUE_SERIAL);
								  
								       for (SomePromise *promise in promises)
								       {
									       [[SomePromise promiseWithName: @"Sub-Promise"
														     dependentOn: promise
																onThread: thread
														        delegate: nil
													       delegateQueue: nil
														       onSuccess: ^(ThenParams)
										                       {
											                      fulfillBlock(Void);
										                       }
														       onReject: ^(ElseParams)
										                       {
											                      fulfillBlock(Void);
										                       }
															   onChain:nil
															   class: class] onSuccess:^(NoResult)
									                           {
										                          __block BOOL shouldRunBlock = NO;
										                          dispatch_sync(sync_queue, ^
														          {
															          promisesCount -= 1;
															          if(promisesCount == 0)
															          {
																        shouldRunBlock = YES;
															          }
														          });
											
										                          if(shouldRunBlock)
										                          {
											                         afterBlock(fulfillBlock,
											                                     rejectBlock,
																			 isRejectedBlock,
																			   progressBlock,
																			 upPromiseResult,
																			          chain);
										                          }
									                           }];
								  }
								  
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
	}
	
	return [SomePromise promiseWithName: name ? name : self.name
							dependentOn: self
							   onThread: thread
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  onSuccess: ^(ThenParams)
							  {
							      id upPromiseResult = result;
								  if(promises.count == 0)
								  {
									  afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
									  return;
								  }
								  
								  __block NSInteger promisesCount = promises.count;
								  dispatch_queue_t sync_queue = dispatch_queue_create("afterPromisesSyncQueue", DISPATCH_QUEUE_SERIAL);
								  
								  for (SomePromise *promise in promises)
								  {
									  [[SomePromise promiseWithName: @"Sub-Promise"
														dependentOn: promise
														   onThread: thread
														   delegate: nil
													  delegateQueue: nil
														  onSuccess: ^(ThenParams)
										{
											fulfillBlock(Void);
										}
														   onReject: ^(ElseParams)
										{
											fulfillBlock(Void);
										}
															onChain:nil
															class: class]
										onSuccess:^(NoResult)
									    {
										   __block BOOL shouldRunBlock = NO;
										   dispatch_sync(sync_queue, ^
														 {
															 promisesCount -= 1;
															 if(promisesCount == 0)
															 {
																 shouldRunBlock = YES;
															 }
														 });
											
										   if(shouldRunBlock)
										   {
											   afterBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, upPromiseResult, chain);
										   }
									     }];
								  }
								  
							  }
							  onReject: ^(ElseParams)
							  {
								  rejectBlock(error);
							  }
							  class: class];
}

//-----------------------------------------------

- (SomePromise *_Nonnull) onRejectExecute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   return [self onRejectOnQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   return [self onRejectWithName: name onQueue: nil execute: body class: class];
}

- (SomePromise *_Nonnull) onRejectOnMainExecute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   return [self onRejectOnQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name onMainExecute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   return [self onRejectWithName: name onQueue: dispatch_get_main_queue() execute: body class: class];
}

- (SomePromise *_Nonnull) onRejectOnQueue:(dispatch_queue_t _Nullable ) queue execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   return [self onRejectWithName: nil onQueue:queue execute: body class: class];
}

- (SomePromise *_Nonnull) onRejectOnThread:(SomePromiseThread *_Nullable) thread execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   return [self onRejectWithName: nil onThread:thread execute: body class: class];
}

- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable ) queue execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   NoFutureBlock block = [body copy];
   _InternalChainHandler *chain = self.chain;
	
   if(self.delegateThread)
   {
	    return [SomePromise promiseWithName: name ? name : self.name
						        dependentOn: self
							        onQueue: queue
							       delegate: self.delegate
						     delegateThread: self.delegateThread
							      onSuccess: ^(ThenParams)
							      {
                                     fulfillBlock(result);
							      }
							      onReject: ^(ElseParams)
							      {
								     block(fulfillBlock,
								            rejectBlock,
									    isRejectedBlock,
									      progressBlock,
									              error,
									              chain);
							      } class: class];
   }
   return [SomePromise promiseWithName: name ? name : self.name
						   dependentOn: self
							   onQueue: queue
							  delegate: self.delegate
						 delegateQueue: self.delegatePromiseQueue
							 onSuccess: ^(ThenParams)
							  {
                                  fulfillBlock(result);
							  }
							  onReject: ^(ElseParams)
							  {
								  block(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, chain);
							  } class: class];
}

- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class
{
   NoFutureBlock block = [body copy];
   _InternalChainHandler *chain = self.chain;
	
   if(self.delegateThread)
   {
	    return [SomePromise promiseWithName: name ? name : self.name
						        dependentOn: self
								   onThread: thread
							       delegate: self.delegate
						     delegateThread: self.delegateThread
							      onSuccess: ^(ThenParams)
							      {
                                     fulfillBlock(result);
							      }
							      onReject: ^(ElseParams)
							      {
								     block(fulfillBlock,
								            rejectBlock,
									    isRejectedBlock,
									      progressBlock,
									              error,
									              chain);
							      } class: class];
   }
   return [SomePromise promiseWithName: name ? name : self.name
						   dependentOn: self
							  onThread: thread
							  delegate: self.delegate
						 delegateQueue: self.delegatePromiseQueue
							 onSuccess: ^(ThenParams)
							  {
                                  fulfillBlock(result);
							  }
							  onReject: ^(ElseParams)
							  {
								  block(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, chain);
							  } class: class];

}

- (SomePromise *_Nonnull) whenExecute:(InitBlock _Nonnull ) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
	return [self whenOnQueue: nil execute: body resultBlock: finalBlock class: class];
}

- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name execute:(InitBlock _Nonnull ) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
	return [self whenWithName: name onQueue: nil execute: body resultBlock: finalBlock class: class];
}

- (SomePromise *_Nonnull) whenOnMainExecute:(InitBlock _Nonnull ) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
	return [self whenOnQueue: dispatch_get_main_queue() execute: body resultBlock: finalBlock class: class];
}

- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name onMainExecute:(InitBlock _Nonnull ) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [self whenWithName: name onQueue: dispatch_get_main_queue() execute: body resultBlock: finalBlock class: class];
}

- (SomePromise *_Nonnull) whenOnQueue: (dispatch_queue_t _Nullable ) queue execute:(InitBlock _Nonnull ) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [self whenWithName: nil onQueue: queue execute: body resultBlock: finalBlock class: class];
}

- (SomePromise *_Nonnull) whenOnThread:(SomePromiseThread *_Nullable) thread execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [self whenWithName: nil onThread: thread execute: body resultBlock: finalBlock class: class];
}

- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name onQueue: (dispatch_queue_t _Nullable ) queue execute:(InitBlock _Nonnull ) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
    if(self.delegateThread)
    {
	    return [SomePromise promiseWithName: name ? name : self.name
							    whenPromise: self
								    onQueue: queue
							       delegate: self.delegate
							 delegateThread: self.delegateThread
							      resolvers: body
								finalResult: finalBlock
								      class: class];
	}
	return [SomePromise promiseWithName: name ? name : self.name
							whenPromise: self
								onQueue: queue
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  resolvers: body
							finalResult: finalBlock
							      class: class];
}

- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
    if(self.delegateThread)
    {
	    return [SomePromise promiseWithName: self.name
							    whenPromise: self
								   onThread: thread
							       delegate: self.delegate
							 delegateThread: self.delegateThread
							      resolvers: body
								finalResult: finalBlock
								      class: class];
	}
	return [SomePromise promiseWithName: self.name
							whenPromise: self
							   onThread: thread
							   delegate: self.delegate
						  delegateQueue: self.delegatePromiseQueue
							  resolvers: body
							finalResult: finalBlock
								  class: class];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysExecute:(AlwaysBlock _Nonnull) body
{
    return [self alwaysOnQueue: nil execute: body];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysOnMainExecute:(AlwaysBlock _Nonnull) body
{
   return [self alwaysOnQueue: dispatch_get_main_queue() execute: body];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysOnQueue: (dispatch_queue_t _Nullable ) queue execute:(AlwaysBlock _Nonnull) body
{
    AlwaysBlock always = [body copy];

	[SomePromise promiseWithName: @"±~`[Я-Always"
					 dependentOn: self
						 onQueue: queue
						delegate: nil
				   delegateQueue: nil
					   onSuccess: ^(ThenParams)
					   {
							always(result, nil);
							fulfillBlock(Void);
					   }
					   onReject: ^(ElseParams)
					   {
					       always(nil, error);
						   fulfillBlock(Void);
					   }
					   class: nil];
    return self;
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysOnThread:(SomePromiseThread *_Nullable) thread execute:(AlwaysBlock _Nonnull) body
{
    AlwaysBlock always = [body copy];

	[SomePromise promiseWithName: @"±~`[Я-Always"
					 dependentOn: self
						onThread: thread
						delegate: nil
				   delegateQueue: nil
					   onSuccess: ^(ThenParams)
					   {
							always(result, nil);
							fulfillBlock(Void);
					   }
					   onReject: ^(ElseParams)
					   {
					       always(nil, error);
						   fulfillBlock(Void);
					   }
					   class: nil];
    return self;
}

//Property methods
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull))then
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, FutureBlock) = ^SomePromise*(Class class, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenExecute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull))thenOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, FutureBlock) = ^SomePromise*(Class class, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenOnMainExecute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull))thenOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, dispatch_queue_t, FutureBlock) = ^SomePromise*(Class class, dispatch_queue_t queue, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenOnQueue: queue execute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull))thenOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, SomePromiseThread *, FutureBlock) = ^SomePromise*(Class class, SomePromiseThread *thread, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenOnThread: thread execute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull))thenWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, FutureBlock) = ^SomePromise*(NSString *name, Class class, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName: name execute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull))thenOnMainWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, FutureBlock) = ^SomePromise*(NSString *name, Class class, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName: name onMainExecute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull))thenOnQueueWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class class, dispatch_queue_t, FutureBlock) = ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName: name onQueue: queue execute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull))thenOnThreadWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, SomePromiseThread *, FutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, FutureBlock futureBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName: name onThread: thread execute: futureBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElse
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, FutureBlock, NoFutureBlock) = ^SomePromise*(Class class, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenExecute:futureBlock elseExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, FutureBlock, NoFutureBlock) = ^SomePromise*(Class class, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenOnMainExecute:futureBlock elseOnMainExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, dispatch_queue_t, FutureBlock, NoFutureBlock) = ^SomePromise*(Class class, dispatch_queue_t queue, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenOnQueue:queue execute:futureBlock elseExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(Class, SomePromiseThread *, FutureBlock, NoFutureBlock) = ^SomePromise*(Class class, SomePromiseThread *thread, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenOnThread:thread execute:futureBlock elseExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, FutureBlock, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName:name execute:futureBlock elseExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnMainWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, FutureBlock, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName:name onMainExecute:futureBlock elseOnMainExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnQueueWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, dispatch_queue_t, FutureBlock, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName:name onQueue:queue execute:futureBlock elseExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnThreadWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   SomePromise*(^thenBlock)(NSString*, Class, SomePromiseThread*, FutureBlock, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, FutureBlock futureBlock, NoFutureBlock elseBlock)
   {
       __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
       return [strongSelf thenWithName:name onThread:thread execute:futureBlock elseExecute:elseBlock class: class];
   };
   return [thenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))after
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, NSTimeInterval, FutureBlock) = ^SomePromise*(Class class, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval execute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, NSTimeInterval, FutureBlock) = ^SomePromise*(Class class, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval onMainExecute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, dispatch_queue_t, NSTimeInterval, FutureBlock) = ^SomePromise*(Class class, dispatch_queue_t queue, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval onQueue: queue execute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, SomePromiseThread *, NSTimeInterval, FutureBlock) = ^SomePromise*(Class class, SomePromiseThread *thread, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval onThread: thread execute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, NSTimeInterval, FutureBlock) = ^SomePromise*(NSString *name, Class class, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval withName: name execute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnMainWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, NSTimeInterval, FutureBlock) = ^SomePromise*(NSString *name, Class class, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval withName: name onMainExecute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnQueueWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, dispatch_queue_t, NSTimeInterval, FutureBlock) = ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval withName: name onQueue: queue execute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnThreadWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, SomePromiseThread*, NSTimeInterval, FutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, NSTimeInterval interval, FutureBlock futureBlock)
    {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf after: interval withName: name onThread: thread execute: futureBlock class: class];
	};
	
	return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromise
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(Class, SomePromise*, FutureBlock) = ^SomePromise*(Class class, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(Class, SomePromise*, FutureBlock) = ^SomePromise*(Class class, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise onMainExecute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(Class, dispatch_queue_t, SomePromise*, FutureBlock) = ^SomePromise*(Class class, dispatch_queue_t queue, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise onQueue: queue execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(Class, SomePromiseThread*, SomePromise*, FutureBlock) = ^SomePromise*(Class class, SomePromiseThread *thread, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise onThread: thread execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(NSString*, Class, SomePromise*, FutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise withName: name execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnMainWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(NSString*, Class, SomePromise*, FutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise withName: name onMainExecute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnQueueWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(NSString*, Class, dispatch_queue_t, SomePromise*, FutureBlock) = ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise withName: name onQueue: queue execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnThreadWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^afterBlock)(NSString*, Class, SomePromiseThread*, SomePromise*, FutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, SomePromise *promise, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromise: promise withName: name onThread: thread execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromises
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(Class class, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnMain
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(Class class, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises onMainExecute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnQueue
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, dispatch_queue_t _Nullable, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(Class class, dispatch_queue_t queue, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises onQueue: queue execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnThread
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(Class, SomePromiseThread *_Nullable, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(Class class, SomePromiseThread *thread, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises onThread: thread execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesWithName
{
    __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(NSString *name, Class class, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises withName: name execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnMainWithName
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(NSString *name, Class class, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises withName: name onMainExecute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnQueueWithName
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, dispatch_queue_t _Nullable, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises withName: name onQueue: queue execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnThreadWithName
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
    SomePromise*(^afterBlock)(NSString*, Class, SomePromiseThread *_Nullable, NSArray<SomePromise*> *, FutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, NSArray<SomePromise*> *promises, FutureBlock futureBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf afterPromises: promises withName: name onThread: thread execute: futureBlock class: class];
	};

    return [afterBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThen
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(Class, NoFutureBlock) = ^SomePromise*(Class class, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectExecute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(Class, NoFutureBlock) = ^SomePromise*(Class class, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectOnMainExecute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(Class, dispatch_queue_t, NoFutureBlock) = ^SomePromise*(Class class, dispatch_queue_t queue, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectOnQueue: queue execute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(Class, SomePromiseThread*, NoFutureBlock) = ^SomePromise*(Class class, SomePromiseThread *thread, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectOnThread: thread execute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(NSString*, Class, NoFutureBlock) = ^SomePromise*(NSString* name, Class class, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectWithName: name execute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnMainWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(NSString*, Class, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectWithName: name onMainExecute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnQueueWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(NSString*, Class, dispatch_queue_t, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectWithName: name onQueue: queue execute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnThreadWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^rejectedBlock)(NSString*, Class, SomePromiseThread*, NoFutureBlock) = ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, NoFutureBlock rejectedBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf onRejectWithName: name onThread: thread execute: rejectedBlock class: class];
	};
	
    return [rejectedBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))when
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(Class, InitBlock, FinalResultBlock) =  ^SomePromise*(Class class, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenExecute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(Class, InitBlock, FinalResultBlock) =  ^SomePromise*(Class class, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenOnMainExecute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(Class, dispatch_queue_t, InitBlock, FinalResultBlock) =  ^SomePromise*(Class class, dispatch_queue_t queue, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenOnQueue: queue execute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(Class, SomePromiseThread*, InitBlock, FinalResultBlock) =  ^SomePromise*(Class class, SomePromiseThread *thread, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenOnThread: thread execute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(NSString*, Class, InitBlock, FinalResultBlock) =  ^SomePromise*(NSString *name, Class class, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenWithName: name execute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnMainWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(NSString*, Class, InitBlock, FinalResultBlock) =  ^SomePromise*(NSString *name, Class class, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenWithName: name onMainExecute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnQueueWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(NSString*, Class, dispatch_queue_t, InitBlock, FinalResultBlock) =  ^SomePromise*(NSString *name, Class class, dispatch_queue_t queue, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenOnQueue: queue execute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnThreadWithName
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	SomePromise*(^whenBlock)(NSString*, Class, SomePromiseThread*, InitBlock, FinalResultBlock) =  ^SomePromise*(NSString *name, Class class, SomePromiseThread *thread, InitBlock initialBlock, FinalResultBlock resultBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf whenOnThread: thread execute: initialBlock resultBlock: resultBlock class: class];
	};
	
	return [whenBlock copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(AlwaysBlock _Nonnull))always
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	id<SomePromiseChainMethodsExecutorStrategyUser>(^alwaysBlock)(AlwaysBlock) = ^id<SomePromiseChainMethodsExecutorStrategyUser>(AlwaysBlock alwaysBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf alwaysExecute: alwaysBlock];
	};

	return [alwaysBlock copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(AlwaysBlock _Nonnull))alwaysOnMain
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	id<SomePromiseChainMethodsExecutorStrategyUser>(^alwaysBlock)(AlwaysBlock) = ^id<SomePromiseChainMethodsExecutorStrategyUser>(AlwaysBlock alwaysBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf alwaysOnMainExecute: alwaysBlock];
	};

	return [alwaysBlock copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, AlwaysBlock _Nonnull))alwaysOnQueue
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	id<SomePromiseChainMethodsExecutorStrategyUser>(^alwaysBlock)(dispatch_queue_t, AlwaysBlock) = ^id<SomePromiseChainMethodsExecutorStrategyUser>(dispatch_queue_t queue, AlwaysBlock alwaysBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf alwaysOnQueue: queue execute: alwaysBlock];
	};
	
	return [alwaysBlock copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, AlwaysBlock _Nonnull))alwaysOnThread
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
	id<SomePromiseChainMethodsExecutorStrategyUser>(^alwaysBlock)(SomePromiseThread*, AlwaysBlock) = ^id<SomePromiseChainMethodsExecutorStrategyUser>(SomePromiseThread *thread, AlwaysBlock alwaysBlock)
	{
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		return [strongSelf alwaysOnThread: thread execute: alwaysBlock];
	};
	
	return [alwaysBlock copy];
}

+ (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id creationBlock, ...))spInternal:(NSString*)method self:(id<SomePromiseChainMethodsExecutorStrategyUser>)selfPointer
{
	__weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = selfPointer;
    return ^(id creationBlock, ...)
	{
	    __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		SomePromise *resultPromise = nil;
		NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
		const char rtype = blockSignature.methodReturnType[0];
		
		//parsing arguments
        va_list args;
        va_start(args, creationBlock);
        va_list args1;
        va_start(args1, creationBlock);
        NSInvocation *blockInvocation = [NSInvocation invocationForBlock:creationBlock withParameters:args1];
        va_end(args1);
        Class class = nil;
        NSString *name = nil;
        dispatch_queue_t queue = nil;
        SomePromiseThread *thread = nil;
        SomeResultProvider *resultProvider = nil;
        SomeProgressBlockProvider *progressProvider = nil;
        SomeIsRejectedBlockProvider *isRejectedProvider = nil;
        SomePromiseDelegateWrapper *delegate = nil;
        dispatch_queue_t delegateQueue = nil;
        SomePromiseThread *delegateThread = nil;
		SomePromiseSettingsObserverWrapper *observers = nil;
		SomeValuesInChainProvider *valuesProvider = nil;
		NSMutableArray *parameters = nil;
		
		parseBlockParams(blockSignature, &class, &name, &queue, &thread, &resultProvider, &progressProvider, &isRejectedProvider, &delegate, &delegateQueue, &delegateThread, &observers, &valuesProvider, &parameters, args);
        va_end(args);
		if(thread)
		{
		    if(delegateThread)
		    {
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onThread:thread delegate:delegate ? delegate.delegate : strongSelf.delegate delegateThread:delegateThread onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
				     if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
				     {
					 	promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					 }
					 else if([method isEqualToString:@"else"])
					 {
						fulfillBlock(result);
					 }
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					 if([method isEqualToString:@"next"]  || [method isEqualToString:@"else"])
				     {
						promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					 }
					 else
					 {
					    rejectBlock(error);
					 }
                } onChain:strongSelf.chain class:class];
			}
			else
			{
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onThread:thread delegate:delegate ? delegate.delegate : strongSelf.delegate delegateQueue:delegateQueue onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
					if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
					{
                       promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					}
					else if([method isEqualToString:@"else"])
					{
						fulfillBlock(result);
					}
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					 if([method isEqualToString:@"next"] || [method isEqualToString:@"else"])
				     {
					    promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					 }
					 else
					 {
					    rejectBlock(error);
					 }
                } onChain:strongSelf.chain class:class];
			}
		}
		else
		{
		    if(delegateThread)
		    {
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onQueue:queue delegate:delegate ? delegate.delegate : strongSelf.delegate delegateThread:delegateThread onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
					if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
					{
                      promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					}
					else if([method isEqualToString:@"else"])
					{
						fulfillBlock(result);
					}
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					if([method isEqualToString:@"next"] || [method isEqualToString:@"else"])
					{
                       promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					}
					else
					{
					   rejectBlock(error);
					}
                } onChain:strongSelf.chain class:class];
			}
			else
			{
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onQueue:queue delegate:delegate ? delegate.delegate : strongSelf.delegate delegateQueue:delegateQueue onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
					if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
					{
                       promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					}
					else if([method isEqualToString:@"else"])
					{
						fulfillBlock(result);
					}
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					if([method isEqualToString:@"next"] || [method isEqualToString:@"else"])
					{
					   promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					}
					else
					{
					   rejectBlock(error);
					}
                } onChain:strongSelf.chain class:class];
			}
		}
        finalizePromise(resultPromise, observers, class, name, queue, thread, delegate, delegateQueue, delegateThread,   resultProvider, progressProvider, isRejectedProvider, valuesProvider);
		
	    return resultPromise;
	};
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id creationBlock, ...))spNext
{
	return [[SomePromiseChainMethodsExecutorStrategy spInternal:@"next" self:self] copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id creationBlock, ...))spThen
{
     return [[SomePromiseChainMethodsExecutorStrategy spInternal:@"then" self:self] copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id creationBlock, ...))spElse
{
     return [[SomePromiseChainMethodsExecutorStrategy spInternal:@"else" self:self] copy];
}

+ (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nullable conditionBlock, id _Nonnull creationBlock, ...))spIfInternal:(NSString*)method self:(id<SomePromiseChainMethodsExecutorStrategyUser>)selfPointer
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = selfPointer;
   return [^(id conditionBlock, id creationBlock, ...)
   {
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		SomePromise *resultPromise = nil;
		NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
		const char rtype = blockSignature.methodReturnType[0];
		id _conditionBlock = [conditionBlock copy];
		//parsing arguments
        va_list args;
        va_start(args, creationBlock);
        va_list args1;
        va_start(args1, creationBlock);
        NSInvocation *blockInvocation = [NSInvocation invocationForBlock:creationBlock withParameters:args1];
        va_end(args1);
        Class class = nil;
        NSString *name = nil;
        dispatch_queue_t queue = nil;
        SomePromiseThread *thread = nil;
        SomeResultProvider *resultProvider = nil;
        SomeProgressBlockProvider *progressProvider = nil;
        SomeIsRejectedBlockProvider *isRejectedProvider = nil;
        SomePromiseDelegateWrapper *delegate = nil;
        dispatch_queue_t delegateQueue = nil;
        SomePromiseThread *delegateThread = nil;
		SomePromiseSettingsObserverWrapper *observers = nil;
		SomeValuesInChainProvider *valuesProvider = nil;
		NSMutableArray *parameters = nil;
		parseBlockParams(blockSignature, &class, &name, &queue, &thread, &resultProvider, &progressProvider, &isRejectedProvider, &delegate, &delegateQueue, &delegateThread, &observers, &valuesProvider, &parameters, args);
		va_end(args);
		if(thread)
		{
		    if(delegateThread)
		    {
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onThread:thread delegate:delegate ? delegate.delegate :  strongSelf.delegate delegateThread:delegateThread onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
				     if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
				     {
				     	if([method isEqualToString:@"then"] && _conditionBlock)
						{
								//check result condition
								BOOL(^_resultConditionBlock)(id result) = _conditionBlock;
								guard (_resultConditionBlock(result)) else {rejectBlock(rejectionErrorWithText(@"Result Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
								}
						}
						else if(_conditionBlock)//"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
					 	promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					 }
					 else if([method isEqualToString:@"else"])
					 {
						fulfillBlock(result);
					 }
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					 if([method isEqualToString:@"next"]  || [method isEqualToString:@"else"])
				     {
						if([method isEqualToString:@"else"] && _conditionBlock)
						{
								BOOL(^_resultConditionBlock)(NSError *error) = _conditionBlock;
								guard (_resultConditionBlock(error)) else {rejectBlock(error);
									return;
								}
						} else if(_conditionBlock) //"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
                        promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					 }
					 else
					 {
					    rejectBlock(error);
					 }
                } onChain:strongSelf.chain class:class];
			}
			else
			{
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onThread:thread delegate:delegate ? delegate.delegate :  strongSelf.delegate delegateQueue:delegateQueue onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
					if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
					{
						if([method isEqualToString:@"then"] && _conditionBlock)
						{
								//check result condition
								BOOL(^_resultConditionBlock)(id result) = _conditionBlock;
								guard (_resultConditionBlock(result)) else {rejectBlock(rejectionErrorWithText(@"Result Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
								}
						}
						else if(_conditionBlock)//"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
					
                       promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					}
					else if([method isEqualToString:@"else"])
					{
						fulfillBlock(result);
					}
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					 if([method isEqualToString:@"next"] || [method isEqualToString:@"else"])
				     {
						if([method isEqualToString:@"else"] && _conditionBlock)
						{
								BOOL(^_resultConditionBlock)(NSError *error) = _conditionBlock;
								guard (_resultConditionBlock(error)) else {rejectBlock(error);
									return;
								}
						} else if(_conditionBlock) //"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
					    promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					 }
					 else
					 {
					    rejectBlock(error);
					 }
                } onChain:strongSelf.chain class:class];
			}
		}
		else
		{
		    if(delegateThread)
		    {
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onQueue:queue delegate:delegate ? delegate.delegate : strongSelf.delegate delegateThread:delegateThread onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
					if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
					{
						if([method isEqualToString:@"then"] && _conditionBlock)
						{
								//check result condition
								BOOL(^_resultConditionBlock)(id result) = _conditionBlock;
								guard (_resultConditionBlock(result)) else {rejectBlock(rejectionErrorWithText(@"Result Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
								}
						}
						else if(_conditionBlock)//"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
					
                      promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					}
					else if([method isEqualToString:@"else"])
					{
						fulfillBlock(result);
					}
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					if([method isEqualToString:@"next"] || [method isEqualToString:@"else"])
					{
						if([method isEqualToString:@"else"] && _conditionBlock)
						{
								BOOL(^_resultConditionBlock)(NSError *error) = _conditionBlock;
								guard (_resultConditionBlock(error)) else {rejectBlock(error);
									return;
								}
						} else if(_conditionBlock) //"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
                       promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					}
					else
					{
					   rejectBlock(error);
					}
                } onChain:strongSelf.chain class:class];
			}
			else
			{
				resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name dependentOn:strongSelf onQueue:queue delegate:delegate ? delegate.delegate : strongSelf.delegate delegateQueue:delegateQueue onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				{
					if([method isEqualToString:@"next"] || [method isEqualToString:@"then"])
					{
						if([method isEqualToString:@"then"] && _conditionBlock)
						{
								//check result condition
								BOOL(^_resultConditionBlock)(id result) = _conditionBlock;
								guard (_resultConditionBlock(result)) else {rejectBlock(rejectionErrorWithText(@"Result Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
								}
						}
						else if(_conditionBlock)//"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
						
                       promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
					}
					else if([method isEqualToString:@"else"])
					{
						fulfillBlock(result);
					}
                } onReject:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *  error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                {
					if([method isEqualToString:@"next"] || [method isEqualToString:@"else"])
					{
						if([method isEqualToString:@"else"] && _conditionBlock)
						{
								BOOL(^_resultConditionBlock)(NSError *error) = _conditionBlock;
								guard (_resultConditionBlock(error)) else {rejectBlock(error);
									return;
								}
						} else if(_conditionBlock) //"next" means if condition
						{
							BOOL(^_resultConditionBlock)(void) = _conditionBlock;
							guard (_resultConditionBlock()) else {rejectBlock(rejectionErrorWithText(@"If Condition is false", ESomePromiseError_ConditionReturnsFalse));
									return;
							}
						}
					
					   promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, error, lastValuesInChain);
					}
					else
					{
					   rejectBlock(error);
					}
                } onChain:strongSelf.chain class:class];
			}
		}
        finalizePromise(resultPromise, observers, class, name, queue, thread, delegate, delegateQueue, delegateThread,   resultProvider, progressProvider, isRejectedProvider, valuesProvider);
		
	    return resultPromise;
   } copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(Condition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spIf
{
   return [[SomePromiseChainMethodsExecutorStrategy spIfInternal:@"next" self:self] copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(CatchCondition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spCatch
{
   return [[SomePromiseChainMethodsExecutorStrategy spIfInternal:@"else" self:self] copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(ThenCondition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spWhere
{
   return [[SomePromiseChainMethodsExecutorStrategy spIfInternal:@"then" self:self] copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(NSTimeInterval timeInterval, id _Nonnull creationBlock, ...))spAfterTime
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   return [^(NSTimeInterval timeInterval, id creationBlock, ...)
   {
   	    __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
	   	SomePromise *resultPromise = nil;
		NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
		const char rtype = blockSignature.methodReturnType[0];
		
		//parsing arguments
        va_list args;
        va_start(args, creationBlock);
        va_list args1;
        va_start(args1, creationBlock);
        NSInvocation *blockInvocation = [NSInvocation invocationForBlock:creationBlock withParameters:args1];
        va_end(args1);
        Class class = nil;
        NSString *name = nil;
        dispatch_queue_t queue = nil;
        SomePromiseThread *thread = nil;
        SomeResultProvider *resultProvider = nil;
        SomeProgressBlockProvider *progressProvider = nil;
        SomeIsRejectedBlockProvider *isRejectedProvider = nil;
        SomePromiseDelegateWrapper *delegate = nil;
        dispatch_queue_t delegateQueue = nil;
        SomePromiseThread *delegateThread = nil;
		SomePromiseSettingsObserverWrapper *observers = nil;
		SomeValuesInChainProvider *valuesProvider = nil;
		NSMutableArray *parameters = nil;
	   
        parseBlockParams(blockSignature, &class, &name, &queue, &thread, &resultProvider, &progressProvider, &isRejectedProvider, &delegate, &delegateQueue, &delegateThread, &observers, &valuesProvider, &parameters, args);
        va_end(args);
		if(thread)
		{
				resultPromise =  [strongSelf after:timeInterval withName:name ? : strongSelf.name onThread:thread execute:^(ThenParams)
				{
				   promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
			    } class:class];
		}
		else
		{
				resultPromise =  [strongSelf after:timeInterval withName:name ? : strongSelf.name onQueue:queue execute:^(ThenParams)
				{
				   promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
			    } class:class];
		}
		
        finalizePromise(resultPromise, observers, class, name, queue, thread, delegate, delegateQueue, delegateThread,   resultProvider, progressProvider, isRejectedProvider, valuesProvider);
		
	    return resultPromise;
   } copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(NSArray<SomePromise*> *_Nullable promises, id _Nonnull creationBlock, ...))spAfter
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   return [^(NSArray<SomePromise*> *promises, id creationBlock, ...)
   {
   	    __strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
	   	SomePromise *resultPromise = nil;
		NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
		const char rtype = blockSignature.methodReturnType[0];
		
		//parsing arguments
        va_list args;
        va_start(args, creationBlock);
        va_list args1;
        va_start(args1, creationBlock);
        NSInvocation *blockInvocation = [NSInvocation invocationForBlock:creationBlock withParameters:args1];
        va_end(args1);
        Class class = nil;
        NSString *name = nil;
        dispatch_queue_t queue = nil;
        SomePromiseThread *thread = nil;
        SomeResultProvider *resultProvider = nil;
        SomeProgressBlockProvider *progressProvider = nil;
        SomeIsRejectedBlockProvider *isRejectedProvider = nil;
        SomePromiseDelegateWrapper *delegate = nil;
        dispatch_queue_t delegateQueue = nil;
        SomePromiseThread *delegateThread = nil;
		SomePromiseSettingsObserverWrapper *observers = nil;
		SomeValuesInChainProvider *valuesProvider = nil;
		NSMutableArray *parameters = nil;

		parseBlockParams(blockSignature, &class, &name, &queue, &thread, &resultProvider, &progressProvider, &isRejectedProvider, &delegate, &delegateQueue, &delegateThread, &observers, &valuesProvider, &parameters, args);
        va_end(args);
		if(thread)
		{
				resultPromise =  [strongSelf afterPromises:promises withName:name ? : strongSelf.name onThread:thread execute:^(ThenParams)
				{
				   promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
			    } class:class];
		}
		else
		{
				resultPromise =  [strongSelf afterPromises:promises withName:name ? : strongSelf.name onQueue:queue execute:^(ThenParams)
				{
				   promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, nil, lastValuesInChain);
			    } class:class];
		}

        finalizePromise(resultPromise, observers, class, name, queue, thread, delegate, delegateQueue, delegateThread,   resultProvider, progressProvider, isRejectedProvider, valuesProvider);
		
	    return resultPromise;
   } copy];
}

- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(FinalResultBlock _Nonnull finalResultBlock, id _Nonnull creationBlock, ...))spWhen
{
   __weak id<SomePromiseChainMethodsExecutorStrategyUser> weakSelf = self;
   return [^(FinalResultBlock finalResultBlock, id creationBlock, ...)
   {
	   	SomePromise *resultPromise = nil;
		NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
		const char rtype = blockSignature.methodReturnType[0];
		__strong id<SomePromiseChainMethodsExecutorStrategyUser> strongSelf = weakSelf;
		//parsing arguments
        va_list args;
        va_start(args, creationBlock);
        va_list args1;
        va_start(args1, creationBlock);
        NSInvocation *blockInvocation = [NSInvocation invocationForBlock:creationBlock withParameters:args1];
        va_end(args1);
        Class class = nil;
        NSString *name = nil;
        dispatch_queue_t queue = nil;
        SomePromiseThread *thread = nil;
        SomeResultProvider *resultProvider = nil;
        SomeProgressBlockProvider *progressProvider = nil;
        SomeIsRejectedBlockProvider *isRejectedProvider = nil;
        SomePromiseDelegateWrapper *delegate = nil;
        dispatch_queue_t delegateQueue = nil;
        SomePromiseThread *delegateThread = nil;
		SomePromiseSettingsObserverWrapper *observers = nil;
		SomeValuesInChainProvider *valuesProvider = nil;
		NSMutableArray *parameters = nil;
		
        parseBlockParams(blockSignature, &class, &name, &queue, &thread, &resultProvider, &progressProvider, &isRejectedProvider, &delegate, &delegateQueue, &delegateThread, &observers, &valuesProvider, &parameters, args);
        va_end(args);
		if(thread)
		{
		
		       if(delegateThread)
		       {
                      resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name
													   whenPromise:strongSelf
														   onThread:thread
								                          delegate:delegate ? delegate.delegate : strongSelf.delegate
							                        delegateThread:delegateThread
								                         resolvers:^(StdBlocks)
				                                         {
				                                            promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, nil, nil);
					                                     }
							                           finalResult:finalResultBlock
							                                 class:class];
				}
				else
				{
					 resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name
													  whenPromise:strongSelf
														   onThread:thread
								                          delegate:delegate ? delegate.delegate : strongSelf.delegate
							                        delegateQueue:delegateQueue
								                         resolvers:^(StdBlocks)
				                                         {
				                                            promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, nil, nil);
					                                     }
							                           finalResult:finalResultBlock
							                                 class:class];
				}
		}
		else
		{
		        if(delegateThread)
		        {
                   resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name
													   whenPromise:strongSelf
														   onQueue:queue
								                          delegate:delegate ? delegate.delegate : strongSelf.delegate
							                        delegateThread:delegateThread
								                         resolvers:^(StdBlocks)
				                                         {
				                                            promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, nil, nil);
					                                     }
							                           finalResult:finalResultBlock
							                                 class:class];
				}
				else
				{
				                   resultPromise = [SomePromise promiseWithName:name ? : strongSelf.name
													   whenPromise:strongSelf
														   onQueue:queue
								                          delegate:delegate ? delegate.delegate : strongSelf.delegate
							                        delegateQueue:delegateQueue
								                         resolvers:^(StdBlocks)
				                                         {
				                                            promiseBlock(valuesProvider, isRejectedProvider, progressProvider, resultProvider, blockInvocation, parameters, rtype)(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, nil, nil, nil);
					                                     }
							                           finalResult:finalResultBlock
							                                 class:class];
				}
		}


        finalizePromise(resultPromise, observers, class, name, queue, thread, delegate, delegateQueue, delegateThread,   resultProvider, progressProvider, isRejectedProvider, valuesProvider);
	   
	    return resultPromise;
   } copy];
}

@end
