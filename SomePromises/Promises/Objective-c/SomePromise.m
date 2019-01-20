//
//  SomePromise.m
//  SomePromises
///
//  Created by Sergey Makeev on 08/01/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromise.h"
#import "SomePromiseChainMethodsExecutorStrategy.h"
#import "SomePromiseUtils.h"
#import "SomePromiseThread.h"
#import <objc/runtime.h>

static SomePromiseThread *__internalTimeoutThread;

static char const * const promisesHashTableTagKey = "InThreadPromisesHashTable";

@interface SomePromiseThread (SomePromiseInternal)

@property (nonatomic, readonly) NSHashTable *promises;

- (void) addPromise:(SomePromise*)promise;
- (void) internalSomePromiseStop;

@end

@implementation SomePromiseThread (SomePromiseInternal)

- (NSHashTable*) promises
{
    NSHashTable *promises = objc_getAssociatedObject(self, promisesHashTableTagKey);
    if(promises == nil) {
        promises = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:1];
        objc_setAssociatedObject(self, promisesHashTableTagKey, promises, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return promises;
}

- (void) addPromise:(SomePromise*)promise
{
    [self.promises addObject:promise];
}

- (void) internalSomePromiseStop
{
    for (SomePromise *promise in self.promises)
    {
		NSError *error = rejectionErrorWithText(@"Thread Stopped", ESomePromiseError_ThreadStopped);
        [promise rejectWithError:error];
	}
	
	[self internalSomePromiseStop];
}

@end


@interface SomePromiseFuture(share_to_promise)

- (instancetype _Nonnull) initInternalWithClass:(Class _Nullable)class owner:(SomePromise *_Nonnull) promise;
- (void) internalResolveWithObject:(id _Nonnull)object;
- (void) internalResolveWithError:(NSError *_Nullable)error;

@end

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

@implementation SomeVoid

+ (instancetype) voidInstance
{
   static SomeVoid *sharedVoid = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
       sharedVoid = [[SomeVoid alloc] init];
   });
   return sharedVoid;
}

@end

@implementation ObserverAsyncWayWrapper

@synthesize queue, thread;

@end

@implementation _InternalChainHandler
@synthesize lastError = _lastError;
@synthesize lastResult = _lastResult;
@synthesize queue = _queue;
@synthesize thread = _thread;

- (instancetype) initWithPromise:(SomePromise*)promise
{
   self = [super init];
	
   if(self)
   {
       _internalQueue = dispatch_queue_create("SomePromisesChainSynchronize", DISPATCH_QUEUE_SERIAL);
       _defaultQueue = dispatch_queue_create("SomePromisesChain", DISPATCH_QUEUE_CONCURRENT);
	   if(promise.status == ESomePromiseSuccess)
	   {
		   _lastResult = promise.result;
	   }
	   else if(promise.status == ESomePromiseRejected)
	   {
		  _lastResult = Void;
	      _lastError = promise.error;
	   }
	   else
	   {
	      _lastResult = Void;
	   }
	   
	   _eachPromiseOnSuccessBlocks = [NSMutableArray new];
	   _eachPromiseOnRejectBlocks = [NSMutableArray new];
	   _eachPromiseOnProgressBlocks = [NSMutableArray new];
       _promises = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
	   [_promises addObject:promise];
	   _chainObservers = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
	   _valuesForName = [NSMutableDictionary new];
   }
   return self;
}

- (void) rejectAll
{
     NSMutableArray *array = [NSMutableArray arrayWithCapacity:_promises.count];
	 dispatch_sync(_internalQueue, ^
     {
		 for (SomePromise *promise in self->_promises)
		 {
		     [array addObject:promise];
		 }
     });
	
	 for (SomePromise *promise in array)
	 {
        [promise reject];
	 }
}

- (void) rejectAllWithName:(NSString*_Nonnull) name
{
     NSMutableArray *array = [NSMutableArray arrayWithCapacity:_promises.count];
	 dispatch_sync(_internalQueue, ^
     {
		 for (SomePromise *promise in self->_promises)
		 {
		     if([promise.name isEqualToString:name])
		     {
		        [array addObject:promise];
			 }
		 }
     });
	
	 for (SomePromise *promise in array)
	 {
        [promise reject];
	 }
}

- (void) rejectAllByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull))rule
{
	 BOOL (^rejectRule)(SomePromise*)  = [rule copy];
	 NSMutableArray *array = [NSMutableArray arrayWithCapacity:_promises.count];
	 dispatch_sync(_internalQueue, ^
     {
		 for (SomePromise *promise in self->_promises)
		 {
		    if(rejectRule(promise))
		    {
		        [array addObject:promise];
			}
		 }
     });
	
	 for (SomePromise *promise in array)
	 {
        [promise reject];
	 }
}

- (void) addPromise:(SomePromise*)promise
{
     dispatch_sync(_internalQueue, ^
     {
		 [self->_promises addObject:promise];
     });
}

- (void) addObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread
{
     if(thread == nil)
     {
        return;
	 }
	
     dispatch_sync(_internalQueue, ^
     {
		 ObserverAsyncWayWrapper *wrapper = [[ObserverAsyncWayWrapper alloc] init];
		 wrapper.thread = thread;
		 [self->_chainObservers  setObject:wrapper forKey:observer];
     });
}

- (void) addObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) _queue
{
     dispatch_sync(_internalQueue, ^
     {
		 dispatch_queue_t queue = _queue;
		 if(queue ==  nil)
		 {
			 queue = self->_defaultQueue;
		 }
		 
		 ObserverAsyncWayWrapper *wrapper = [[ObserverAsyncWayWrapper alloc] init];
		 wrapper.queue = queue;
		 [self->_chainObservers  setObject:wrapper forKey:observer];
     });
}

- (void) removeObserver:(id<SomePromiseObserver> _Nonnull) observer
{
	 dispatch_sync(_internalQueue, ^
     {
		 [self->_chainObservers removeObjectForKey:observer];
     });
}

- (void) removeObservers
{
	 dispatch_sync(_internalQueue, ^
     {
		 [self->_chainObservers removeAllObjects];
	 });
}

- (void) addOnSuccess:(onEachSuccessBlock _Nonnull) body
{
     dispatch_sync(_internalQueue, ^
     {
		 [self->_eachPromiseOnSuccessBlocks addObject:[body copy]];
     });
}

- (void) addOnReject:(OnEachRejectBlock _Nonnull) body
{
     dispatch_sync(_internalQueue, ^
     {
		 [self->_eachPromiseOnRejectBlocks addObject:[body copy]];
     });
}

- (void) addOnProgress:(OnEachProgressBlock _Nonnull) body
{
     dispatch_sync(_internalQueue, ^
     {
		 [self->_eachPromiseOnProgressBlocks addObject:[body copy]];
     });

}

- (void) _addValue:(id) value withName:(NSString*) name
{
	_valuesForName[name] = value;
}

- (id) valueByName:(NSString*) name
{
     __block id result = nil;
	 dispatch_sync(_internalQueue, ^
     {
		 result = self->_valuesForName[name];
     });
     
     return result;
}

- (void) promise:(SomePromise *_Nonnull) promise gotResult:(id _Nonnull ) result
{
    dispatch_sync(_internalQueue, ^
    {
		self->_lastResult = result;
		[self _addValue:result withName:promise.name];
		for(onEachSuccessBlock block in self->_eachPromiseOnSuccessBlocks)
		{
		
		    if(self.queue)
		    {
			   dispatch_async(self.queue, ^{
                  block(promise.name, result);
			   });
			}
			else if(self.thread)
			{
			   [self.thread performBlock:^{
                  block(promise.name, result);
               }];
			}
			else
			{
			  dispatch_async(self->_defaultQueue, ^{
                 block(promise.name, result);
              });
			}
		}
		
		for (id<SomePromiseObserver> observer in self->_chainObservers)
        {
			if ([self->_chainObservers objectForKey:observer].queue)
			{
			   dispatch_async([self->_chainObservers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:gotResult:)])
		          {
				    [observer promise:promise gotResult:result];
				  }
			   });
			}
			else
			{
			   [[self->_chainObservers objectForKey:observer].thread performBlock:^(){
				  if([observer respondsToSelector:@selector(promise:gotResult:)])
		          {
				    [observer promise:promise gotResult:result];
				  }
			   }];
			}
		}
	});
}

- (void) promise:(SomePromise *_Nonnull) promise rejectedWithError:(NSError *_Nullable) error
{
    dispatch_sync(_internalQueue, ^
    {
		self->_lastError = error;
		[self _addValue:error withName:promise.name];
		for(OnEachRejectBlock block in self->_eachPromiseOnRejectBlocks)
		{
		    if(self.queue)
		    {
			   dispatch_async(self.queue, ^{
                  block(promise.name, error);
			   });
			}
			else if(self.thread)
			{
			   [self.thread performBlock:^{
                  block(promise.name, error);
               }];
			}
			else
			{
			  dispatch_async(self->_defaultQueue, ^{
                 block(promise.name, error);
              });
			}
		}
		
		for (id<SomePromiseObserver> observer in self->_chainObservers)
        {
            if ([self->_chainObservers objectForKey:observer].queue)
			{
			   dispatch_async([self->_chainObservers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:rejectedWithError:)])
				  {
				     [observer promise:promise rejectedWithError:error];
			      }
			   });
			}
			else
			{
				[[self->_chainObservers objectForKey:observer].thread performBlock:^()
				{
				  if([observer respondsToSelector:@selector(promise:rejectedWithError:)])
				  {
				     [observer promise:promise rejectedWithError:error];
			      }
			    }];
			}
		}
	});
}

- (void) promise:(SomePromise *_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
    dispatch_sync(_internalQueue, ^
    {
		for (id<SomePromiseObserver> observer in self->_chainObservers)
        {
            if ([self->_chainObservers objectForKey:observer].queue)
            {
			   dispatch_async([self->_chainObservers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:stateChangedFrom:to:)])
		          {
				     [observer promise:promise stateChangedFrom:oldStatus to:newStatus];
			      }
			   });
			}
			else
			{
			   [[self->_chainObservers objectForKey:observer].thread performBlock:^()
			   {
				  if([observer respondsToSelector:@selector(promise:stateChangedFrom:to:)])
		          {
				     [observer promise:promise stateChangedFrom:oldStatus to:newStatus];
			      }
			   }];
			}
		}
	});
}

- (void) promise:(SomePromise *_Nonnull) promise progress:(float) progress
{
    dispatch_sync(_internalQueue, ^
    {
		for(OnEachProgressBlock block in self->_eachPromiseOnProgressBlocks)
		{
		    if(self.queue)
		    {
			   dispatch_async(self.queue, ^{
                  block(promise.name, progress);
			   });
			}
			else if(self.thread)
			{
			   [self.thread performBlock:^{
                  block(promise.name, progress);
               }];
			}
			else
			{
			  dispatch_async(self->_defaultQueue, ^{
                 block(promise.name, progress);
              });
			}
		}
		
		for (id<SomePromiseObserver> observer in self->_chainObservers)
        {
            if ([self->_chainObservers objectForKey:observer].queue)
            {
			   dispatch_async([self->_chainObservers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:progress:)])
		          {
				     [observer promise:promise progress:progress];
			      }
			   });
			}
			else
			{
			   [[self->_chainObservers objectForKey:observer].thread performBlock:^()
			   {
				  if([observer respondsToSelector:@selector(promise:progress:)])
		          {
				     [observer promise:promise progress:progress];
			      }
			   }];
			}
		}
	});
}

- (NSError*) lastError
{
    __block NSError *result = nil;
	dispatch_sync(_internalQueue, ^
    {
		result = self->_lastError;
	});
    return result;
}

- (id) lastResult
{
    __block id result = nil;
	dispatch_sync(_internalQueue, ^
    {
		result = self->_lastResult;
	});
    return result;
}

- (id _Nullable) lastResultInChain
{
    return self.lastResult;
}

-  (NSError *_Nullable) lastErrorInChain
{
    return self.lastError;
}

- (void) setChainThread:(SomePromiseThread*)thread
{
   if (thread == self.thread || thread == nil)
   {
	   return;
   }
	
   self.queue = nil;
   self.thread = thread;
}

- (SomePromiseThread*)chainThread
{
   return self.thread;
}

- (void) setChainQueue:(dispatch_queue_t)queue
{
   if(queue == self.queue || queue == nil)
   {
      return;
   }
	
   self.thread = nil;
   self.queue = queue;
}

- (dispatch_queue_t)chainQueue
{
   if(self.queue)
   {
	  return self.queue;
   }
	
   if(self.thread)
   {
      return nil;
   }
	
   return _defaultQueue;
}

@end

@interface _SomeWhenPromise : SomePromise <WhenPromiseProtocol>
{
   FulfillBlock _firstFulfillBlock; //to be used inside own initBlock, before final result block
   RejectBlock _firstRejectBlock;
   FinalResultBlock _finalBlock;
   id _selfResult;
   NSError *_selfError;
	
   BOOL _ownerResolved;
   BOOL _selfResolved;
}

@property (nonatomic, copy) FulfillBlock firstFulfillBlock;
@property (nonatomic, copy) RejectBlock firstRejectBlock;
@property (nonatomic, copy) FinalResultBlock finalResultBlock;
@property (nonatomic, strong) id selfResult;
@property (nonatomic, strong) NSError *selfError;
@property (nonatomic, readwrite) BOOL ownerResolved;
@property (nonatomic, readwrite) BOOL selfResolved;

- (instancetype) initWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							      onChain:(_InternalChainHandler* _Nonnull) chain
								   thread:(SomePromiseThread* _Nullable) thread
						   delegateThread:(SomePromiseThread* _Nullable) delegateThread
						            class:(Class _Nullable)class;

@end

@interface SomePromise() <DependentPromiseProtocol>
{
    NSMapTable<id<SomePromiseObserver>, ObserverAsyncWayWrapper *> *_observers;
    NSMutableArray<id<DependentPromiseProtocol> > *_dependantPromises;
    NSMutableArray<id<WhenPromiseProtocol> > *_whenPromises;
	
    NSMutableArray<OnSuccessBlock> *_onSuccessBlocks;
    NSMutableArray<OnRejectBlock> *_onRejectBlocks;
    NSMutableArray<OnProgressBlock> *_onProgressBlocks;
	
    _InternalChainHandler *_chain;
	
    SomePromiseFuture *_future;
	
    NSMutableArray *_providers;
}

@property (nonatomic, strong, readonly) SomePromiseFuture *future;
@property (nonatomic, strong) SomePromise *agent;
@property (nonatomic, strong) dispatch_queue_t statusPromiseQueue;
@property (nonatomic, readonly) dispatch_queue_t defaultPromiseQueue;
@property (nonatomic, readonly) SomePromiseThread *thread;
@property (nonatomic, strong) SomePromiseThread *delegateThread;
@property (nonatomic, readwrite) PromiseStatus status;
@property (nonatomic, strong) id _Nullable result;
@property (nonatomic, strong) NSError* _Nullable error;
@property (nonatomic, weak) id<SomePromiseDelegate> delegate;
@property (nonatomic, readwrite)dispatch_queue_t delegatePromiseQueue;
@property (nonatomic, copy) FulfillBlock fulfillBlock;
@property (nonatomic, copy) RejectBlock rejectBlock;
@property (nonatomic, copy) RejectBlock subRejectBlock;
@property (nonatomic, copy) IsRejectedBlock isRejectedBlock;
@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, readonly) InitBlock _Nullable initBlock;
@property (nonatomic, readonly) FutureBlock _Nullable futureBlock;
@property (nonatomic, readonly) NoFutureBlock _Nullable noFutureBlock;

@property (nonatomic, readwrite) float progress; //comletion progress.
@property (nonatomic, copy) NSString *_Nonnull name;
@property (nonatomic, readonly) NSMapTable<id<SomePromiseObserver>, ObserverAsyncWayWrapper *> *observers;
@property (nonatomic, readonly) NSMutableArray<id<DependentPromiseProtocol> > *dependantPromises;
@property (nonatomic, readonly) NSMutableArray<id<WhenPromiseProtocol> >*whenPromises;
@property (nonatomic, readonly) NSMutableArray<OnSuccessBlock> *onSuccessBlocks;
@property (nonatomic, readonly) NSMutableArray<OnRejectBlock> *onRejectBlocks;
@property (nonatomic, readonly) NSMutableArray<OnProgressBlock> *onProgressBlocks;

@property (nonatomic, strong) _InternalChainHandler *chain;

@property (nonatomic, readonly) SomePromiseThread *onHandlerThread;
@property (nonatomic, readonly) dispatch_queue_t onHandlerQueue;

@property (nonatomic, strong) id ownerResult;
@property (nonatomic, strong) NSError *ownerError;

@property (nonatomic, readwrite) SomePromiseSettings *startSettings;
@end

@implementation SomePromise
{
   InitBlock _initBlock;
   FutureBlock _futureBlock;
   NoFutureBlock _noFutureBlock;

   FulfillBlock _fulfillBlock;
   RejectBlock _rejectBlock;
   RejectBlock _subRejectBlock;
   dispatch_queue_t _statusPromiseQueue;
   dispatch_queue_t _defaultPromiseQueue;
   dispatch_queue_t _delegatePromiseQueue;
   __weak id<SomePromiseDelegate> _delegate;
	
   NSString *_name;
	
   SomePromiseThread *_thread;
   SomePromiseThread *_delegateThread;
	
   SomePromiseThread *_onHandlerThread;
   dispatch_queue_t _onHandlerQueue;
	
   NSTimer *_timeoutTimer;
	
   @protected
   id _ownerResult;
   NSError *_ownerError;
}

@synthesize future = _future;
@synthesize status = _status;
@synthesize statusPromiseQueue = _statusPromiseQueue;
@synthesize fulfillBlock = _fulfillBlock;
@synthesize rejectBlock = _rejectBlock;
@synthesize subRejectBlock = _subRejectBlock;
@synthesize initBlock = _initBlock;
@synthesize futureBlock = _futureBlock;
@synthesize noFutureBlock = _noFutureBlock;
@synthesize delegate = _delegate;
@synthesize delegatePromiseQueue = _delegatePromiseQueue;
@synthesize name = _name;
@synthesize progress = _progress;
@synthesize observers = _observers;
@synthesize dependantPromises = _dependantPromises;
@synthesize whenPromises = _whenPromises;
@synthesize defaultPromiseQueue = _defaultPromiseQueue;
@synthesize thread = _thread;
@synthesize delegateThread = _delegateThread;
@synthesize onSuccessBlocks = _onSuccessBlocks;
@synthesize onRejectBlocks = _onRejectBlocks;
@synthesize onProgressBlocks = _onProgressBlocks;
@synthesize chain = _chain;
@synthesize onHandlerThread = _onHandlerThread;
@synthesize onHandlerQueue = _onHandlerQueue;
@synthesize ownerError = _ownerError;
@synthesize ownerResult = _ownerResult;

- (SomePromiseThread*) promiseThread
{
   return self.thread;
}

- (dispatch_queue_t) promiseQueue
{
   return self.defaultPromiseQueue;
}

- (void) privateAddWhen:(id<WhenPromiseProtocol>) when
{
   dispatch_sync(self.statusPromiseQueue, ^
   {
	   [self->_whenPromises addObject:when];
   });
}

- (void) privateAddToDependancy:(id<DependentPromiseProtocol>) dependee
{
	if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
	       if (ESomePromiseSuccess == [self internalStatusGetter])
	       {
			   [dependee ownerDoneWithResult:self->_result];
	       }
	       else if (ESomePromiseRejected == [self internalStatusGetter])
	       {
			   [dependee ownerFailedWithError:self->_error];
	       }
	       else
	       {
			   [self->_dependantPromises addObject:dependee];
	       }
	   });
	}
	else
	{
	   if (ESomePromiseSuccess == self.status)
	   {
	      [dependee ownerDoneWithResult:self.result];
	   }
	   else
	   {
		  [dependee ownerFailedWithError:self.error];
	   }
	}
}

- (SomePromise *_Nonnull) setChainThread:(SomePromiseThread*_Nullable)thread
{
    [_chain setChainThread:thread];
    return self;
}

- (SomePromiseThread *_Nullable)getChainThread
{
   return [_chain chainThread];
}

- (SomePromise *_Nonnull) setChainQueue:(dispatch_queue_t _Nullable)queue
{
    [_chain setChainQueue:queue];
    return self;
}

- (dispatch_queue_t _Nullable)getChainQueue
{
   return [_chain chainQueue];
}

+ (instancetype _Nullable) promiseWithSettings:(SomePromiseSettings *_Nonnull)settings
{
   guard ([settings consistent]) else {return nil;}
   if(settings.resolvers.finalResultBlock)
   {
       return [[_SomeWhenPromise alloc] initWithSettings:settings];
   }
   return [[SomePromise alloc] initWithSettings:settings];
}


+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                resolvers:(InitBlock _Nonnull) initBlock
                                class:(Class _Nullable) class
{
   return [[SomePromise alloc] initWithName:name
                                      block:[initBlock copy]
                                      queue: nil
								   delegate: nil
							  delegateQueue: nil
								 postPonded: NO
									onChain: nil
									 thread: nil
							 delegateThread: nil
									  class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: nil
							      postPonded: NO
							         onChain: nil
									  thread: nil
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable) class
{
   return  [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: queue
									delegate: nil
							   delegateQueue: nil
							      postPonded: NO
							         onChain: nil
									  thread: nil
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable) class
{
   return  [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
                                       queue: queue
									delegate: delegate
							   delegateQueue: nil
							      postPonded: NO
							         onChain: nil
							          thread: nil
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: queue
									delegate: delegate
							   delegateQueue: delegateQueue
								  postPonded: NO
									 onChain: nil
									  thread: nil
							  delegateThread: nil
							           class: class];
}

//thread
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable ) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: nil
								  postPonded: NO
									 onChain: nil
									  thread: nil
							  delegateThread: delegateThread
							           class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
                                  onThread:(SomePromiseThread *_Nullable ) thread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: nil
							   delegateQueue: nil
								  postPonded: NO
									 onChain: nil
									  thread: thread
							  delegateThread: nil
							           class: class];

}

+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: nil
								  postPonded: NO
									 onChain: nil
									  thread: thread
							  delegateThread: delegateThread
							           class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: delegateQueue
								  postPonded: NO
									 onChain: nil
									  thread: thread
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable) class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: queue
									delegate: delegate
							   delegateQueue: nil
								  postPonded: NO
									 onChain: nil
									  thread: nil
							  delegateThread: delegateThread
							           class: class];
}


//-------------------------postponded---------------------------------------------------------------

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name
                                resolvers:(InitBlock _Nonnull) initBlock
                                    class:(Class _Nullable) class
{
	return [[SomePromise alloc] initWithName:name
	                                   block:[initBlock copy]
	                                   queue: nil
									delegate: nil
							   delegateQueue: nil
							      postPonded: YES
							         onChain: nil
							          thread: nil
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class
{
	return [[SomePromise alloc] initWithName:name
	                                   block:[initBlock copy]
	                                   queue: nil
									delegate: delegate
							   delegateQueue: nil
							      postPonded: YES
							         onChain: nil
									  thread: nil
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class
{
	return  [[SomePromise alloc] initWithName:name
	                                    block:[initBlock copy]
	                                    queue: queue
									 delegate: nil
								delegateQueue: nil
								   postPonded: YES
									  onChain: nil
									   thread: nil
							   delegateThread: nil
										class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class
{
	return  [[SomePromise alloc] initWithName:name
	                                    block:[initBlock copy]
	                                    queue: queue
									 delegate: delegate
							    delegateQueue: nil
							       postPonded: YES
							          onChain: nil
									   thread: nil
							   delegateThread: nil
							            class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class
{
	return  [[SomePromise alloc] initWithName:name
	                                    block:[initBlock copy]
	                                    queue: queue
									 delegate: delegate
								delegateQueue: delegateQueue
								   postPonded: YES
								      onChain: nil
									   thread: nil
							   delegateThread: nil
							            class: class];
}

//thread
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable ) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: nil
								  postPonded: YES
									 onChain: nil
									  thread: nil
							  delegateThread: delegateThread
							           class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name
                                  onThread:(SomePromiseThread *_Nullable ) thread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: nil
							   delegateQueue: nil
								  postPonded: YES
									 onChain: nil
									  thread: thread
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: nil
								  postPonded: YES
									 onChain: nil
									  thread: thread
							  delegateThread: delegateThread
							           class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: nil
									delegate: delegate
							   delegateQueue: delegateQueue
								  postPonded: YES
									 onChain: nil
									  thread: thread
							  delegateThread: nil
							           class: class];
}

+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class
{
    return [[SomePromise alloc] initWithName:name
                                       block:[initBlock copy]
									   queue: queue
									delegate: delegate
							   delegateQueue: nil
								  postPonded: YES
									 onChain: nil
									  thread: nil
							  delegateThread: delegateThread
							           class: class];
}

//---------predefined---------------------------------

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
									value:(id _Nonnull) object
									class:(Class _Nullable)class
{
	SomePromise *promise = [[SomePromise alloc] initWithName:name value:object class: class];
	promise.chain = [[_InternalChainHandler alloc] initWithPromise:promise];
	return promise;
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
									error:(NSError*_Nullable) error
									class:(Class _Nullable)class
{
    SomePromise *promise = [[SomePromise alloc] initWithName:name error:error class: class];
    promise.chain = [[_InternalChainHandler alloc] initWithPromise:promise];
	return promise;
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
									value:(id _Nonnull ) object
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						            class:(Class _Nullable)class
{
	SomePromise *promise = [[SomePromise alloc] initWithName:name value:object class: class];
	promise.chain = [[_InternalChainHandler alloc] initWithPromise:promise];
    promise.delegate = delegate;
    promise.delegateThread = delegateThread;
	return promise;
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
									error:(NSError*_Nullable) error
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						            class:(Class _Nullable)class
{
    SomePromise *promise = [[SomePromise alloc] initWithName:name error:error class: class];
    promise.chain = [[_InternalChainHandler alloc] initWithPromise:promise];
	promise.delegate = delegate;
    promise.delegateThread = delegateThread;
	return promise;
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
									value:(id _Nonnull ) object
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						            class:(Class _Nullable)class
{
	SomePromise *promise = [[SomePromise alloc] initWithName:name value:object class: class];
	promise.chain = [[_InternalChainHandler alloc] initWithPromise:promise];
    promise.delegate = delegate;
    promise.delegatePromiseQueue = delegateQueue;
	return promise;
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
									error:(NSError*_Nullable) error
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						            class:(Class _Nullable)class
{
    SomePromise *promise = [[SomePromise alloc] initWithName:name error:error class: class];
    promise.chain = [[_InternalChainHandler alloc] initWithPromise:promise];
	promise.delegate = delegate;
    promise.delegatePromiseQueue = delegateQueue;
	return promise;
}

//---------dependent-----------------------------------------


+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
									class:(Class _Nullable)class
{
     return [SomePromise promiseWithName: name
                             dependentOn: ownerPromise
								 onQueue: nil
								delegate: nil
						   delegateQueue: nil
							   onSuccess: futureBlock
								onReject: errorBlock
								   class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable ) queue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								    class:(Class _Nullable)class
{
     return [SomePromise promiseWithName: name
                             dependentOn: ownerPromise
								 onQueue: nil
								delegate: nil
						   delegateQueue: nil
							   onSuccess: futureBlock
								onReject: errorBlock
								   class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								    class:(Class _Nullable)class
{
     return [SomePromise promiseWithName: name
                             dependentOn: ownerPromise
								 onQueue: nil
								delegate: nil
						   delegateQueue: nil
			                   onSuccess: futureBlock
								onReject: errorBlock
								   class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								    class:(Class _Nullable)class
{
	return [[SomePromise alloc] initWithName: name
								 dependendOn: ownerPromise
									 onQueue: queue
									delegate: delegate
							   delegateQueue: delegateQueue
								   onSuccess: futureBlock
									onReject: errorBlock
									 onChain: ownerPromise.chain
									  thread: nil
							  delegateThread: nil
							           class: class];
}

//thread
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: nil
									  delegate: nil
								 delegateQueue: nil
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: ownerPromise.chain
										thread: thread
							    delegateThread: nil
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegatThread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
									class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: nil
									  delegate: delegate
								 delegateQueue: nil
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: ownerPromise.chain
										thread: nil
							    delegateThread: delegatThread
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegatThread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: nil
									  delegate: delegate
								 delegateQueue: nil
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: ownerPromise.chain
										thread: thread
							    delegateThread: delegatThread
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable) delegateQueue
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: nil
									  delegate: delegate
								 delegateQueue: delegateQueue
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: ownerPromise.chain
										thread: thread
							    delegateThread: nil
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegatThread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: queue
									  delegate: delegate
								 delegateQueue: nil
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: ownerPromise.chain
										thread: nil
							    delegateThread: delegatThread
							             class: class];
}

//--------when promises----------------------------------------------------------

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(SomePromise*_Nonnull) ownerPromise
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
									class:(Class _Nullable)class
{
			return [SomePromise	promiseWithName: name
                                    whenPromise: ownerPromise
                                        onQueue: nil
								       delegate: nil
							      delegateQueue: nil
								      resolvers: initBlock
							        finalResult: finalBlock
							              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(SomePromise*_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class
{
			return [SomePromise	promiseWithName: name
                                    whenPromise: ownerPromise
                                        onQueue: queue
								       delegate: nil
							      delegateQueue: nil
								      resolvers: initBlock
							        finalResult: finalBlock
							              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(SomePromise*_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class
{
			return [SomePromise	promiseWithName: name
                                    whenPromise: ownerPromise
                                        onQueue: nil
								       delegate: delegate
							      delegateQueue: delegateQueue
								      resolvers: initBlock
							        finalResult: finalBlock
							              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(SomePromise*_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class
{
   return [SomePromise	promiseWithName: name
						    whenPromise: ownerPromise
								onQueue: nil
							   delegate: delegate
						  delegateQueue: delegateQueue
							  resolvers: initBlock
							finalResult: finalBlock
							   onThread: nil
						 delegateThread: nil
						          class: class];
}

//thread
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable) finalBlock
							        class:(Class _Nullable)class
{
			return [SomePromise	promiseWithName: name
                                    whenPromise: ownerPromise
									   onThread: thread
								       delegate: nil
							      delegateQueue: nil
								      resolvers: initBlock
							        finalResult: finalBlock
							              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable) finalBlock
							        class:(Class _Nullable)class
{
			return [SomePromise	promiseWithName: name
                                    whenPromise: ownerPromise
									    onQueue: nil
								       delegate: delegate
								 delegateThread: delegateThread
								      resolvers: initBlock
							        finalResult: finalBlock
							              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class
{
   return [SomePromise	promiseWithName: name
						    whenPromise: ownerPromise
                                        onQueue: nil
								       delegate: delegate
							      delegateQueue: nil
								      resolvers: initBlock
							        finalResult: finalBlock
		                               onThread: thread
								 delegateThread: delegateThread
								          class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class
{
   return [SomePromise	promiseWithName: name
							whenPromise: ownerPromise
								onQueue: nil
							   delegate: delegate
						  delegateQueue: delegateQueue
							  resolvers: initBlock
							finalResult: finalBlock
							   onThread: thread
					     delegateThread: nil
					              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
									class:(Class _Nullable)class
{
   return [SomePromise	promiseWithName: name
							whenPromise: ownerPromise
								onQueue: queue
							   delegate: delegate
						  delegateQueue: nil
							  resolvers: initBlock
							finalResult: finalBlock
							   onThread: nil
					     delegateThread: delegateThread
					              class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
                                 onThread:(SomePromiseThread *_Nullable) thread
						   delegateThread:(SomePromiseThread *_Nullable) delegateThread
						            class:(Class _Nullable)class
{
	if (ESomePromiseSuccess == ownerPromise.status)
	{
	    return [SomePromise promiseWithName:name value:[ownerPromise getFuture] class: class];
	}
	else if (ESomePromiseRejected == ownerPromise.status)
	{
		return [SomePromise promiseWithName:name error:[ownerPromise getFuture] class: class];
	}
	
	SomePromise* promise =  (SomePromise*) [[_SomeWhenPromise alloc] initWithName: name
	                                                                  whenPromise: ownerPromise
	                                                                      onQueue: queue
																		 delegate: delegate
	                                                                delegateQueue: delegateQueue
																		resolvers: initBlock
	                                                                  finalResult: finalBlock
	                                                                      onChain: ownerPromise.chain
															               thread: thread
						                                           delegateThread: delegateThread
						                                                    class: class];

	[ownerPromise.chain addPromise:promise];
	return promise;
}

//init

- (void) commonInitPart
{
	_observers = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
	_dependantPromises = [NSMutableArray array];
	_whenPromises = [NSMutableArray array];
	_onSuccessBlocks = [NSMutableArray array];
	_onRejectBlocks = [NSMutableArray array];
	_onProgressBlocks = [NSMutableArray array];
	_providers = [NSMutableArray array];
}

- (instancetype) initWithName:(NSString*_Nonnull)name
                  dependendOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
                      onQueue:(dispatch_queue_t _Nullable ) queue
					 delegate:(id<SomePromiseDelegate> _Nullable) delegate
				delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
					onSuccess:(FutureBlock _Nonnull ) futureBlock
					 onReject:(NoFutureBlock _Nullable ) errorBlock
					  onChain:(_InternalChainHandler* _Nullable) chain
					   thread:(SomePromiseThread* _Nullable) thread
			   delegateThread:(SomePromiseThread* _Nullable) delegateThread
			            class:(Class _Nullable)class
{
    self = [super init];
    if (self)
    {
	  _future = [[SomePromiseFuture alloc] initInternalWithClass:class owner:self];
	  [self commonInitPart];
	  self.name = name;

	   self.statusPromiseQueue = dispatch_queue_create([NSString stringWithFormat:@"SomePromisesSynchronizeQueueForPromoseWithName %@", self.name].UTF8String, DISPATCH_QUEUE_SERIAL);
		
	   _thread = thread;
	   if (_thread == nil)
	   {
	      _defaultPromiseQueue =  queue ? queue : dispatch_queue_create([NSString stringWithFormat:@"SomePromisesDataStoreQueueForPromoseWithName %@", self.name].UTF8String, DISPATCH_QUEUE_CONCURRENT);
	   }
	   else
	   {
	      [_thread addPromise:self];
	   }
		
	   _delegateThread = delegateThread;
	   if (_delegateThread == nil && _thread == nil)
	   {
          _delegatePromiseQueue = delegateQueue ? delegateQueue : _defaultPromiseQueue;
	   }
	   else if(_delegateThread == nil && delegateQueue == nil)
	   {
	      _delegateThread = _thread;
	   }
	   else
	   {
	      _delegatePromiseQueue = delegateQueue;
	   }
	   _delegate = delegate;
       _futureBlock = futureBlock;
       _noFutureBlock = errorBlock;
       if(![name isEqualToString:@"±~`[Я-Always"])
       {
          _chain = chain;
          [_chain addPromise:self];
	   }
       [self prepareInternalBlocks];
		
       dispatch_sync(_statusPromiseQueue, ^
       {
          self.status = ESomePromisePending;
       });

		//AddToDependeces
		[ownerPromise privateAddToDependancy:self];
	}
	
	return self;
}

- (instancetype) initWithName:(NSString*_Nonnull) name
                        value:(id _Nonnull) object
                        class:(Class _Nullable)class
{
    self = [super init];
    if (self)
    {
		_future = [[SomePromiseFuture alloc] initInternalWithClass:class owner:self];
		[_future internalResolveWithObject:object];
        [self commonInitPart];
        self.name = name;
        self.status = ESomePromiseSuccess;
        self.result = object;
        _chain = [[_InternalChainHandler alloc] initWithPromise:self];
	}
	
	return self;
}

- (instancetype) initWithName:(NSString*_Nonnull) name
                        error:(NSError*_Nullable) error
                        class:(Class _Nullable)class
{
    self = [super init];
    if (self)
    {
		_future = [[SomePromiseFuture alloc] initInternalWithClass:class owner:self];
		[_future internalResolveWithError:error];
        [self commonInitPart];
        self.name = name;
        self.status = ESomePromiseRejected;
        self.error = error;
        _chain = [[_InternalChainHandler alloc] initWithPromise:self];
	}
	
	return self;
}

- (instancetype) initWithSettings:(SomePromiseSettings*)settings
{
   self = [super init];
   if(self)
   {
       self.startSettings = settings;
	   _future = [[SomePromiseFuture alloc] initInternalWithClass:settings.class owner:self];
       [self commonInitPart];
       self.name = settings.name;
	   self.statusPromiseQueue = dispatch_queue_create([NSString stringWithFormat:@"SomePromisesSynchronizeQueueForPromoseWithName %@", self.name].UTF8String, DISPATCH_QUEUE_SERIAL);
	   _thread = settings.worker.thread;
	   _defaultPromiseQueue = settings.worker.queue;
	   
	   if(_thread == nil && _defaultPromiseQueue == nil)
	   {
	      _defaultPromiseQueue = dispatch_queue_create([NSString stringWithFormat:@"SomePromisesDataStoreQueueForPromoseWithName %@", self.name].UTF8String, DISPATCH_QUEUE_CONCURRENT);
	   }
	   
	   if(settings.chain == nil)
       {
	      _chain = [[_InternalChainHandler alloc] initWithPromise:self];
	   }
	   else
	   {
	      _chain = settings.chain;
		  [_chain addPromise:self];
	   }
	   
	   self.ownerResult = settings.ownerValue;
	   self.ownerError = settings.ownerError;

	   self.delegate = settings.delegate.delegate;
	   self.delegatePromiseQueue =  settings.delegateWorker.queue;
	   self.delegateThread = self.delegatePromiseQueue ? nil : settings.delegateWorker.thread;
	   if(self.delegate && self.delegateThread == nil && self.delegatePromiseQueue == nil)
	   {
		  self.delegatePromiseQueue = _defaultPromiseQueue;
	   }
	   _observers = settings.observers.observers;
	   
	   _onSuccessBlocks = [settings.onSuccessBlocks.onSuccessBlocks mutableCopy];
	   _onRejectBlocks = [settings.onRejectBlocks.onRejectBlocks mutableCopy];
	   _onProgressBlocks = [settings.onProgressBlocks.onProgressBlocks mutableCopy];
	   
	   _initBlock = [settings.resolvers.initBlock copy];
	   
	   _futureBlock = [settings.resolvers.futureBlock copy];
	   _noFutureBlock = [settings.resolvers.noFutureBlock copy];
	   
	   if(_futureBlock != nil || _noFutureBlock != nil || _initBlock == nil)
	   {
           __weak SomePromise *weakSelf = self;
		   _initBlock = ^(StdBlocks)
		   {
		       __strong SomePromise *strongSelf = weakSelf;
			   if(strongSelf.ownerResult)
			   {
			      if(strongSelf.futureBlock)
			      {
					  strongSelf.futureBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, strongSelf.ownerResult, strongSelf.chain);
				  }
				  else fulfillBlock(strongSelf.ownerResult);
			   }
			   else
			   {
			      if(strongSelf.noFutureBlock)
			      {
					  strongSelf.noFutureBlock(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, strongSelf.ownerError, strongSelf.chain);
				  }
				  else
				  {
				     return rejectBlock(strongSelf.ownerError);
				  }
			   }
		   };
	   }
	   
	   if(settings.status == ESomePromisePending || settings.status == ESomePromiseUnknown || settings.status == ESomePromiseNonActive)
	   {
	      _status = ESomePromiseNonActive;
	      [self prepareInternalBlocks];
	      [self start];
	   }
	   else
	   {
		  _status = settings.status;
	   }
   }
   return self;
}


- (instancetype) initWithName:(NSString *_Nonnull) name
                        block:(InitBlock _Nonnull) initblock
                        queue:(dispatch_queue_t) queue
					 delegate:(id<SomePromiseDelegate> _Nullable) delegate
				delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
				   postPonded:(BOOL) postPonded
                      onChain:(_InternalChainHandler* _Nullable) chain
                       thread:(SomePromiseThread* _Nullable) thread
			   delegateThread:(SomePromiseThread* _Nullable) delegateThread
			            class:(Class _Nullable)class
{
   self = [super init];
   if (self)
   {
       _future = [[SomePromiseFuture alloc] initInternalWithClass:class owner:self];
       [self commonInitPart];
       self.name = name;
       self.statusPromiseQueue = dispatch_queue_create([NSString stringWithFormat:@"SomePromisesSynchronizeQueueForPromoseWithName %@", self.name].UTF8String, DISPATCH_QUEUE_SERIAL);
       _thread = thread;
       if (_thread == nil)
       {
	      _defaultPromiseQueue =  queue ? queue : dispatch_queue_create([NSString stringWithFormat:@"SomePromisesDataStoreQueueForPromoseWithName %@", self.name].UTF8String, DISPATCH_QUEUE_CONCURRENT);
	   }
	   else
	   {
	      [_thread addPromise:self];
	   }
	   _delegateThread = delegateThread;
	   if (_delegateThread == nil && _thread == nil)
	   {
          _delegatePromiseQueue = delegateQueue ? delegateQueue : _defaultPromiseQueue;
	   }
	   else if(_delegateThread == nil && delegateQueue == nil)
	   {
	      _delegateThread = _thread;
	   }
	   else
	   {
	      _delegatePromiseQueue = delegateQueue;
	   }
	   _delegate = delegate;
       _initBlock = initblock;
       if(chain == nil)
       {
	      _chain = [[_InternalChainHandler alloc] initWithPromise:self];
	   }
	   else
	   {
	      _chain = chain;
		  [_chain addPromise:self];
	   }
       [self prepareInternalBlocks];
       
       dispatch_sync(_statusPromiseQueue, ^
       {
          self.status = ESomePromiseNonActive;
       });
	   
	   if (!postPonded)
	   {
          [self start];
	   }
   }
	
   return self;
}

- (void) rejectAllInChain
{
   [self.chain rejectAll];
}

- (void) rejectAllInChainWithName:(NSString*_Nonnull) name
{
   [self.chain rejectAllWithName:name];
}

- (void) rejectAllInChainByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull))rule
{
	[self.chain rejectAllByRule:rule];
}

- (void) reject
{
   NSError *error = rejectionErrorWithText(@"User Rejected", ESomePromiseError_UserRejected);
   [self rejectWithError:error];
}

- (void) _rejectAllDependences
{
    for (SomePromise *dependee in _dependantPromises)
    {
		[dependee reject];
	}
	
	[_dependantPromises removeAllObjects];
}

- (void) rejectAllDependences
{
   if(self.statusPromiseQueue)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
          [self _rejectAllDependences];
       });
	}
	else
	{
	   [self _rejectAllDependences];
	}
}

- (void) _rejectDependencesWithName:(NSString*_Nonnull) name
{
    NSMutableArray *toRemove = [NSMutableArray new];
    for (SomePromise *dependee in _dependantPromises)
    {
        if([dependee.name isEqualToString:name])
        {
		   [dependee reject];
		   [toRemove addObject:dependee];
		}
	}
	
	[_dependantPromises removeObjectsInArray:toRemove];
}

- (void) rejectDependencesWithName:(NSString*_Nonnull) name
{
   if(self.statusPromiseQueue)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
          [self _rejectDependencesWithName: name];
       });
	}
	else
	{
	   [self _rejectDependencesWithName: name];
	}
}

- (void) _rejectDependenceByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull promise)) rule
{
	NSMutableArray *toRemove = [NSMutableArray new];
    for (SomePromise *dependee in _dependantPromises)
    {
       if(rule(dependee))
       {
          [dependee reject];
          [toRemove addObject:dependee];
	   }
    }
	
    [_dependantPromises removeObjectsInArray:toRemove];
}

- (void) rejectDependenceByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull promise)) rule
{
	   if(self.statusPromiseQueue)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
          [self _rejectDependenceByRule: [rule copy]];
       });
	}
	else
	{
	   [self _rejectDependenceByRule: [rule copy]];
	}
}

- (void) rejectWithError:(NSError* _Nullable) error
{
   self.agent = nil;
   __block BOOL alreadyResolved = NO;
	guard(_statusPromiseQueue) else {return;}
   dispatch_sync(_statusPromiseQueue, ^
   {
        if(ESomePromiseSuccess == [self internalStatusGetter] || ESomePromiseRejected == [self internalStatusGetter])
        {
           alreadyResolved = YES;
           return; //Promise already resolved.
		}
        self.status = ESomePromiseRejected;
        self.error = error;
        [self.future internalResolveWithError:error];
   });
	
   if (alreadyResolved)
   {
      return;
   }
	
   if (self.delegate)
   {
        if(self.delegateThread)
        {
            [self.delegateThread performBlock:^{
		       if([self.delegate respondsToSelector:@selector(promise:rejectedWithError:)])
		       {
				  [self.delegate promise: self rejectedWithError:error];
			   }
			}];
		}
		else
		{
		   dispatch_async(self.delegatePromiseQueue, ^
		   {
		       if([self.delegate respondsToSelector:@selector(promise:rejectedWithError:)])
		       {
				  [self.delegate promise: self rejectedWithError:error];
			   }
		   });
		}
   }
   dispatch_sync(_statusPromiseQueue, ^
   {
        for (id<SomePromiseObserver> observer in self.observers)
        {
            SomePromiseThread *thread = [self.observers objectForKey:observer].thread;
			if(thread)
			{
			   [thread performBlock:^{
				  if([observer respondsToSelector:@selector(promise:rejectedWithError:)])
		          {
				     [observer promise: self rejectedWithError:error];
			      }
               }];
			}
			else
			{
			   dispatch_async([self.observers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:rejectedWithError:)])
		          {
				     [observer promise: self rejectedWithError:error];
			      }
			   });
			}
		}
		
		 for(OnRejectBlock rejectblock in self.onRejectBlocks)
		 {
		     if(self.onHandlerThread == nil &&
		        self.onHandlerQueue == nil)
			{
		        if(self.thread)
		        {
			       [self.thread performBlock:^{
                      rejectblock(error);
                   }];
			    }
			    else
			    {
		           dispatch_async(self.defaultPromiseQueue, ^
		           {
		             rejectblock(error);
			       });
			    }
			}
			else
			{
				if(self.onHandlerThread)
		        {
			       [self.onHandlerThread performBlock:^{
                      rejectblock(error);
                   }];
			    }
			    else
			    {
		           dispatch_async(self.onHandlerQueue, ^
		           {
		             rejectblock(error);
			       });
			    }
			}
		 }
		
		 for (id<DependentPromiseProtocol> dependee in self.dependantPromises)
		 {
			[dependee ownerFailedWithError:error];
		 }
		 
		 [self.dependantPromises removeAllObjects];
		 for (id<WhenPromiseProtocol> whenPromise in self.whenPromises)
		 {
		     [whenPromise ownerFinishedWith:nil error:error];
		 }
   });
   if(self.subRejectBlock)
   {
	  self.subRejectBlock(error);
   }
}

- (void) templateMethodStart
{
   if(self.initBlock)
   {
      self.initBlock(self.fulfillBlock, self.rejectBlock, self.isRejectedBlock, self.progressBlock);
   }
}

- (void) start
{
  __block BOOL shouldStart = NO;
  if (ESomePromiseNonActive == self.status)
  {
     dispatch_sync(_statusPromiseQueue, ^
     {
		 if (ESomePromiseNonActive == self->_status)
	    {
		   self.status = ESomePromisePending;
		   shouldStart = YES;
	    }
     });
  }
  else
  {
     shouldStart = NO;
  }
	
  if (shouldStart)
  {
     __weak SomePromise *weakSelf = self;
	 self.agent = self;
	 if(_thread)
	 {
	    [_thread performBlock:^{
	       [weakSelf templateMethodStart];
        }];
	 }
	 else
	 {
        dispatch_async(_defaultPromiseQueue, ^
        {
	       [weakSelf templateMethodStart];
        });
	 }
	  
	 dispatch_sync(_statusPromiseQueue, ^
     {
		for (SomePromise *whenPromise in self->_whenPromises)
        {
            [whenPromise start];
		}
     });
  }
  #ifdef DEBUG
  else
  {
	NSLog(@"Promise %@ can't be started", self.name);
  }
  #endif
}

- (void) internalAddObserver:(id<SomePromiseObserver> _Nonnull) observer onQueueOrThread:(ObserverAsyncWayWrapper *) queueOrThread
{
    if(queueOrThread.queue == nil && queueOrThread.thread == nil)
    {
		queueOrThread.queue = _defaultPromiseQueue;
	}
	[_observers setObject:queueOrThread forKey:observer];
}

- (BOOL) resolved
{
	PromiseStatus currentStatus = self.status;
	return (ESomePromiseSuccess == currentStatus || ESomePromiseRejected == currentStatus);
		
}

- (SomePromise *_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
           ObserverAsyncWayWrapper *queue = [[ObserverAsyncWayWrapper alloc] init];
           queue.queue = self->_defaultPromiseQueue;
		   [self internalAddObserver:observer onQueueOrThread:queue];
	   });
	}
	
	return self;
}

- (SomePromise *_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) queue
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
		  ObserverAsyncWayWrapper *wrappedQueue = [[ObserverAsyncWayWrapper alloc] init];
		  wrappedQueue.queue = queue;
          [self internalAddObserver:observer onQueueOrThread:wrappedQueue];
		});
	}
	
	return self;
}

- (SomePromise *_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
		  ObserverAsyncWayWrapper *wrappedThread = [[ObserverAsyncWayWrapper alloc] init];
		  wrappedThread.thread = thread;
          [self internalAddObserver:observer onQueueOrThread:wrappedThread];
		});
	}
	
	return self;
}

- (SomePromise *_Nonnull) addObserverOnMain:(id<SomePromiseObserver> _Nonnull) observer
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
		  ObserverAsyncWayWrapper *wrappedQueue = [[ObserverAsyncWayWrapper alloc] init];
		  wrappedQueue.queue = dispatch_get_main_queue();
         [self internalAddObserver:observer onQueueOrThread:wrappedQueue];
	   });
	}
	
	return self;
}

- (SomePromise *_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers
{
	return [self addObservers:observers onQueue:_defaultPromiseQueue];
}

- (SomePromise *_Nonnull) addObserversOnMain:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers
{
    return [self addObservers:observers onQueue:dispatch_get_main_queue()];
}

- (SomePromise *_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers onQueue:(dispatch_queue_t _Nullable) queue
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
           for (id<SomePromiseObserver> observer in observers)
           {
			  ObserverAsyncWayWrapper *wrappedQueue = [[ObserverAsyncWayWrapper alloc] init];
			  wrappedQueue.queue = queue;
		      [self internalAddObserver:observer onQueueOrThread:wrappedQueue];
	       }
		});
	}
	
	return self;
}

- (SomePromise *_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers onThread:(SomePromiseThread *_Nonnull) thread
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
           for (id<SomePromiseObserver> observer in observers)
           {
			  ObserverAsyncWayWrapper *wrappedThread = [[ObserverAsyncWayWrapper alloc] init];
			  wrappedThread.thread = thread;
		      [self internalAddObserver:observer onQueueOrThread:wrappedThread];
	       }
		});
	}
	
	return self;
}

- (SomePromise *_Nonnull) removeObserver:(id<SomePromiseObserver> _Nonnull) observer
{
    if ([self resolved])
    {
		[self.observers removeObjectForKey:observer];
	}
	else
	{
	   dispatch_sync(self.statusPromiseQueue, ^
	   {
		  [self.observers removeObjectForKey:observer];
	   });
	}
	
	return self;
}

- (SomePromise *_Nonnull) removeObservers
{
    if (![self resolved])
    {
       dispatch_sync(self.statusPromiseQueue, ^
       {
          [self.observers removeAllObjects];
		});
	}
	else
	{
	   [self.observers removeAllObjects];
	}
	
	return self;
}

- (void) addOnSuccess:(OnSuccessBlock _Nonnull) body
{
   if(ESomePromiseSuccess == self.status)
   {
       id result = self.result;
       if(self.thread)
       {
		  [self.thread performBlock:^{
              body(result);
		  }];
	   }
	   else
	   {
	      dispatch_async(self.defaultPromiseQueue, ^{
              body(result);
          });
	   }
   }
   else if (ESomePromiseRejected != self.status)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
		   if(ESomePromiseSuccess != self->_status)
		   {
		      [self->_onSuccessBlocks addObject:[body copy]];
		   }
		   else
		   {
		      id result = self->_result;
			  dispatch_async(self.defaultPromiseQueue, ^{
                 body(result);
             });
		   }
	   });
   }
}

- (void) addOnReject:(OnRejectBlock _Nonnull) body
{
   if (ESomePromiseRejected == self.status)
   {
       NSError *error = self.error;
       if(self.thread)
       {
		  [self.thread performBlock:^{
              body(error);
		  }];
	   }
	   else
	   {
	      dispatch_async(self.defaultPromiseQueue, ^{
              body(error);
          });
	   }
   }
   else	if(ESomePromiseSuccess != self.status)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
		   [self->_onRejectBlocks addObject:[body copy]];
	   });
   }
}

- (void) addOnProgress:(OnProgressBlock _Nonnull) body
{
   if(self.status != ESomePromiseSuccess && self.status != ESomePromiseRejected)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
		   [self->_onProgressBlocks addObject:[body copy]];
	   });
   }
}

- (SomePromise *_Nonnull) onSuccess:(OnSuccessBlock _Nonnull) body
{
     [self addOnSuccess:body];
     return self;
}

- (SomePromise *_Nonnull) onReject:(OnRejectBlock _Nonnull) body
{
      [self addOnReject:body];
      return self;
}

- (SomePromise *_Nonnull) onProgress:(OnProgressBlock _Nonnull) body
{
      [self addOnProgress:body];
      return self;
}

- (SomePromise *_Nonnull) onEachSuccess:(onEachSuccessBlock _Nonnull) body
{
    [_chain addOnSuccess:body];
    return self;
}

- (SomePromise *_Nonnull) onEachReject:(OnEachRejectBlock _Nonnull) body
{
    [_chain addOnReject:body];
    return self;
}

- (SomePromise *_Nonnull) onEachProgress:(OnEachProgressBlock _Nonnull) body
{
    [_chain addOnProgress:body];
    return self;
}

- (SomePromise *_Nonnull) addChainObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) _queue
{
    [_chain addObserver:observer onQueue:_queue];
    return self;
}

- (SomePromise *_Nonnull) addChainObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread
{
    [_chain addObserver:observer onThread:thread];
    return self;
}

- (SomePromise *_Nonnull) removeChainObserver:(id<SomePromiseObserver> _Nonnull) observer
{
    [_chain removeObserver:observer];
    return self;
}

- (SomePromise *_Nonnull) removeChainObservers
{
   [_chain removeObservers];
   return self;
}

- (void) destroyDependences
{
	   if ([_dependantPromises count])
	   {
		  for (id<DependentPromiseProtocol> dependee in _dependantPromises)
		  {
			 [dependee ownerReleased];
		  }
		   
		  [_dependantPromises removeAllObjects];
	   }
}

- (void) addTimeout:(NSTimeInterval)timeout
{
  if(_timeoutTimer)
  {
     [_timeoutTimer invalidate];
  }
	
  //reset timer
  __weak SomePromise *weakSelf = self;
  _timeoutTimer = [__internalTimeoutThread scheduledTimerWithTimeInterval:timeout repeats:NO block:^(NSTimer *timer) {
	      __strong SomePromise *strongSelf = weakSelf;
	      if(strongSelf)
	      {
			 NSError *error = rejectionErrorWithText(@"Timeout", ESomePromiseError_Timeout);
	         [strongSelf rejectWithError:error];
		  }
      }];
}

- (SomePromise *_Nonnull)timeout:(NSTimeInterval)timeout
{
  [self addTimeout:timeout];
  return self;
}

- (SomePromise *_Nonnull (^ __nonnull)(NSTimeInterval))addTimeout
{
  __weak SomePromise *weakSelf = self;
   SomePromise*(^addTimeoutBlock)(NSTimeInterval) = ^SomePromise*(NSTimeInterval interval)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf timeout:interval];
   };
	
   return [addTimeoutBlock copy];
}

- (SomePromise *_Nonnull)removeTimeout
{
  if(_timeoutTimer)
  {
     [_timeoutTimer invalidate];
     _timeoutTimer = nil;
  }
  return self;
}

- (SomePromise *_Nonnull (^ __nonnull)(void))declineTimeout
{
  __weak SomePromise *weakSelf = self;
   SomePromise*(^declineTimeoutBlock)(void) = ^SomePromise*()
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf removeTimeout];
   };
	
   return [declineTimeoutBlock copy];
}

///
- (void) addObserversQueue:(dispatch_queue_t _Nonnull) queue
{
   dispatch_sync(self.statusPromiseQueue, ^
   {
      self->_onHandlerQueue = queue;
      self->_onHandlerThread = nil;
   });
}

- (void) addObserversThread:(SomePromiseThread *_Nonnull) thread
{
   dispatch_sync(self.statusPromiseQueue, ^
   {
      self->_onHandlerQueue = nil;
      self->_onHandlerThread = thread;
   });
}

- (SomePromise *_Nonnull) observersQueue:(dispatch_queue_t _Nonnull) queue
{
   [self addObserversQueue:queue];
   return self;
}

- (SomePromise *_Nonnull) observersThread:(SomePromiseThread *_Nonnull) thread
{
  [self addObserversThread:thread];
  return self;
}

- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t  _Nonnull)) observersQueue
{
  __weak SomePromise *weakSelf = self;
   SomePromise*(^addOnHandlerQueueBlock)(dispatch_queue_t) = ^SomePromise*(dispatch_queue_t queue)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf observersQueue:queue];
   };
	
   return [addOnHandlerQueueBlock copy];
}
- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread  *_Nonnull)) observersThread
{
  __weak SomePromise *weakSelf = self;
   SomePromise*(^addOnHandlerThreadBlock)(SomePromiseThread*) = ^SomePromise*(SomePromiseThread *thread)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf observersThread:thread];
   };
	
   return [addOnHandlerThreadBlock copy];
}

////

- (id _Nullable) lastResultInChain
{
      return self.chain.lastResult;
}

-  (NSError *_Nullable) lastErrorInChain
{
      return self.chain.lastError;
}

- (void) dealloc
{
   if(self.status != ESomePromiseSuccess &&
      self.status != ESomePromiseRejected)
   {
       dispatch_sync(self.statusPromiseQueue, ^
       {
          [self destroyDependences];
       });
   }
   else
   {
       [self destroyDependences];
   }

   if(_timeoutTimer)
   {
      [_timeoutTimer invalidate];
   }
#ifdef DEBUG
   NSLog(@"Promise %@ deallocated", self.name);
#endif
}

- (void) prepareInternalBlocks
{
   __weak SomePromise *weakSelf = self;
   self.fulfillBlock = ^void(id object) {
      __strong SomePromise *strongSelf = weakSelf;
      if(strongSelf == nil)
      {
         return;
	  }
      //1 change value and state
      __block id result = nil;
      __block BOOL warningNeeded = NO;
      dispatch_sync(strongSelf.statusPromiseQueue, ^
      {
	     if (ESomePromisePending != [strongSelf internalStatusGetter])
	     {
             strongSelf.agent = nil;
			 return;
		 }
         strongSelf.status = ESomePromiseSuccess;
         strongSelf.result = object;
         result = object;
         warningNeeded = YES;
      });
	   
	  if (result == nil)
	  {
	     if(warningNeeded)
	     {
		    NSLog(@"SomePromise Warning: %@ promise's fulfill block got nil as the result. Check if the promise is rejected and stop it's running or check that previous promise in chain did not send nil as a result", strongSelf.name);
		 }
	     return;
	  }
	  
      if (strongSelf.delegate)
      {
	    if(strongSelf.delegateThread)
	    {
			[strongSelf.delegateThread performBlock:^{
		      if ([strongSelf.delegate respondsToSelector:@selector(promise:gotResult:)])
		      {
			     [strongSelf.delegate promise:strongSelf gotResult:result];
			  }
			}];
		}
		else
		{
		   if(strongSelf.delegateThread)
		   {
		      [strongSelf.delegateThread performBlock:^{
		         if ([strongSelf.delegate respondsToSelector:@selector(promise:gotResult:)])
		         {
			        [strongSelf.delegate promise:strongSelf gotResult:result];
			     }
			  }];
		   }
		   else
		   {
		      dispatch_async(strongSelf.delegatePromiseQueue, ^
		      {
		         if ([strongSelf.delegate respondsToSelector:@selector(promise:gotResult:)])
		         {
			        [strongSelf.delegate promise:strongSelf gotResult:result];
			     }
		      });
		   }
		}
	  }
	  dispatch_sync(strongSelf.statusPromiseQueue, ^
      {
        for (id<SomePromiseObserver> observer in strongSelf.observers)
        {
            SomePromiseThread *thread = [strongSelf.observers objectForKey:observer].thread;
            if(thread)
            {
				[thread performBlock:^(){
				   if([observer respondsToSelector:@selector(promise:gotResult:)])
		           {
				     [observer promise:strongSelf gotResult:result];
			       }
				}];
			}
			else
			{
			   dispatch_async([strongSelf.observers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:gotResult:)])
		          {
				    [observer promise:strongSelf gotResult:result];
			      }
			   });
			}
		 }
		 
		 for(OnSuccessBlock completeblock in strongSelf.onSuccessBlocks)
		 {
		     if(strongSelf.onHandlerThread == nil &&
		        strongSelf.onHandlerQueue == nil)
		     {
		        if(strongSelf.thread)
		        {
			       [strongSelf.thread performBlock:^{
				     completeblock(result);
				   }];
			    }
			    else
			    {
		          dispatch_async(strongSelf.defaultPromiseQueue, ^
				  {
		            completeblock(result);
			      });
			    }
			}
			else
			{
				if(strongSelf.onHandlerThread)
		        {
			       [strongSelf.onHandlerThread performBlock:^{
				     completeblock(result);
				   }];
			    }
			    else
			    {
		          dispatch_async(strongSelf.onHandlerQueue, ^
				  {
		            completeblock(result);
			      });
			    }
			}
		 }
		 
		 [strongSelf.chain promise:strongSelf gotResult:result];
		 
		 for (id<DependentPromiseProtocol> dependee in strongSelf.dependantPromises)
		 {
		     [dependee ownerDoneWithResult:result];
		 }
		 [strongSelf.dependantPromises removeAllObjects];
		 
		 for (id<WhenPromiseProtocol> whenPromise in strongSelf.whenPromises)
		 {
		     [whenPromise ownerFinishedWith:result error:nil];
		 }
		 
		 [strongSelf.future internalResolveWithObject:result];
       });

      strongSelf.agent = nil;
   };
   
   self.rejectBlock = ^void(NSError *error) {
      __strong SomePromise *strongSelf = weakSelf;
	  if(strongSelf == nil)
      {
         return;
	  }
      __block BOOL wasRejected = NO;
      dispatch_sync(strongSelf.statusPromiseQueue, ^
      {
	      if(ESomePromiseSuccess == [strongSelf internalStatusGetter] || ESomePromiseRejected == [strongSelf internalStatusGetter])
          {
             strongSelf.agent = nil;
             return; //Promise already resolved.
		  }
		  
          strongSelf.status = ESomePromiseRejected;
          strongSelf.error = error;
          wasRejected = YES;
      });
	   
	  if(!wasRejected) {return;}
	   
      if (strongSelf.delegate)
      {
        if(strongSelf.delegateThread)
        {
		    [strongSelf.delegateThread performBlock:^{
		       if([strongSelf.delegate respondsToSelector:@selector(promise:rejectedWithError:)])
		       {
				  [strongSelf.delegate promise: strongSelf rejectedWithError:error];
			   }
			}];
		}
		else
		{
		   dispatch_async(strongSelf.delegatePromiseQueue, ^
		   {
		       if([strongSelf.delegate respondsToSelector:@selector(promise:rejectedWithError:)])
		       {
				  [strongSelf.delegate promise: strongSelf rejectedWithError:error];
			   }
		   });
		}
	  }
	  
	  dispatch_sync(strongSelf.statusPromiseQueue, ^
      {
        for (id<SomePromiseObserver> observer in strongSelf.observers)
        {
            SomePromiseThread *thread = [strongSelf.observers objectForKey:observer].thread;
            if(thread)
            {
			   [thread performBlock:^{
				   if([observer respondsToSelector:@selector(promise:rejectedWithError:)])
		           {
				      [observer promise:strongSelf rejectedWithError:error];
			       }
               }];
			}
			else
			{
			   dispatch_async([strongSelf.observers objectForKey:observer].queue, ^
			   {
				  if([observer respondsToSelector:@selector(promise:rejectedWithError:)])
		          {
				     [observer promise:strongSelf rejectedWithError:error];
			      }
			   });
			}
		 }
		 
		for(OnRejectBlock rejectblock in strongSelf.onRejectBlocks)
		 {
			if(strongSelf.onHandlerThread == nil &&
		        strongSelf.onHandlerQueue == nil)
			{
		        if(strongSelf.thread)
		        {
			       [strongSelf.thread performBlock:^{
                     rejectblock(error);
                   }];
			    }
			    else
			    {
		           dispatch_async(strongSelf.defaultPromiseQueue, ^
		           {
		              rejectblock(error);
			       });
			    }
			}
			else
			{
		        if(strongSelf.onHandlerThread)
		        {
			       [strongSelf.onHandlerThread performBlock:^{
                     rejectblock(error);
                   }];
			    }
			    else
			    {
		           dispatch_async(strongSelf.onHandlerQueue, ^
		           {
		              rejectblock(error);
			       });
			    }
			}
		 }

		 [strongSelf.chain promise:strongSelf rejectedWithError:error];
		 
	     for (id<DependentPromiseProtocol> dependee in strongSelf.dependantPromises)
		 {
		     [dependee ownerFailedWithError:error];
		 }
		 [strongSelf.dependantPromises removeAllObjects];

		 for (id<WhenPromiseProtocol> whenPromise in strongSelf.whenPromises)
		 {
		     [whenPromise ownerFinishedWith:nil error:error];
		 }
		 
		 [strongSelf.future internalResolveWithError:error];

       });

      strongSelf.agent = nil;
   };
	
   self.isRejectedBlock = ^BOOL(){
	  __strong SomePromise *strongSelf = weakSelf;
	  if(strongSelf == nil)
      {
         return YES;
	  }
	  __block BOOL result = NO;
	  dispatch_sync(strongSelf.statusPromiseQueue, ^
	  {
	     result = (ESomePromiseRejected == [strongSelf internalStatusGetter]);
	  });
	  
	  return result;
   };
	
   self.progressBlock = ^void(float progress){
	  __strong SomePromise *strongSelf = weakSelf;
	  if(strongSelf == nil)
      {
         return;
	  }
	  strongSelf.progress = progress;
   };
}

- (PromiseStatus) status
{
      if(!_statusPromiseQueue)
      {
         return _status;
	  }
      __block PromiseStatus status = 0;
      dispatch_sync(_statusPromiseQueue, ^
      {
		  status = self->_status;
      });
      return status;
}

//should be sync_called inside _statusPromiseQueue
- (void) setStatus:(PromiseStatus)status
{
   PromiseStatus oldStatus = _status;
   if (ESomePromiseSuccess == oldStatus || ESomePromiseRejected == oldStatus)
   {
      return; //can't change resolved promise
   }
   PromiseStatus newStatus = status;
   _status = newStatus;

	if(self.delegate)
	{
		if([self.delegate respondsToSelector:@selector(promise:stateChangedFrom:to:)])
		{
		    if(self.delegateThread)
		    {
				[self.delegateThread performBlock:^{
                   [self.delegate promise: self stateChangedFrom: oldStatus to:newStatus];
                }];
			}
			else
			{
			   dispatch_async(self.delegatePromiseQueue, ^
			   {
				   [self.delegate promise: self stateChangedFrom: oldStatus to:newStatus];
			   });
			}
		}
	}
	
	for (id<SomePromiseObserver> observer in self.observers)
	{
	    SomePromiseThread *thread = [self.observers objectForKey:observer].thread;
	    if(thread)
	    {
		    [thread performBlock:^{
					if([observer respondsToSelector:@selector(promise:stateChangedFrom:to:)])
					{
					    [observer promise:self stateChangedFrom:oldStatus to:newStatus];
					}
			}];
		}
	    else
	    {
		   dispatch_async([self.observers objectForKey:observer].queue, ^
		   {
				if([observer respondsToSelector:@selector(promise:stateChangedFrom:to:)])
				{
					[observer promise:self stateChangedFrom:oldStatus to:newStatus];
				}
		   });
	    }
	}
	
	[self.chain promise:self stateChangedFrom:oldStatus to:newStatus];
}

- (PromiseStatus) internalStatusGetter
{
   return _status;
}

- (SomePromiseFuture*) getFuture
{
	return _future;
}

- (SomePromiseSettings*) settings
{
   SomePromiseMutableSettings *settings = [[SomePromiseMutableSettings alloc] init];
   PromiseStatus status = self.status;
   settings.name = self.name;
   settings.status = status;
   settings.error = self.error;
   settings.value = self.result;
   settings.ownerError = self.ownerError;
   settings.ownerValue = self.ownerResult;
	
   SomePromiseSettingsPromiseWorker *promiseWorker = [[SomePromiseSettingsPromiseWorker alloc] init];
   promiseWorker.queue = self.promiseQueue;
   promiseWorker.thread = self.thread;
	
   settings.worker = promiseWorker;
	
   settings.delegate = [[SomePromiseDelegateWrapper alloc] init];
   settings.delegate.delegate = self.delegate;
	
   SomePromiseSettingsPromiseDelegateWorker *promiseDelegateWorker = [[SomePromiseSettingsPromiseDelegateWorker alloc] init];
   promiseDelegateWorker.queue = self.delegatePromiseQueue;
   promiseDelegateWorker.thread = self.thread;
   settings.delegateWorker = promiseDelegateWorker;
	
   settings.resolved = ((status == ESomePromiseSuccess) || (status == ESomePromiseRejected));
   settings.forcedRejected = NO;
	
   SomePromiseSettingsOnSuccessBlocksWrapper *onSuccessBlocks = [[SomePromiseSettingsOnSuccessBlocksWrapper alloc] init];
   onSuccessBlocks.onSuccessBlocks = [self.onSuccessBlocks copy];
   SomePromiseSettingsOnRejectBlocksWrapper *onRejectBlocks = [[SomePromiseSettingsOnRejectBlocksWrapper alloc] init];
   onRejectBlocks.onRejectBlocks = [self.onRejectBlocks copy];
   SomePromiseSettingsOnProgressBlocksWrapper *onProgressBlocks = [[SomePromiseSettingsOnProgressBlocksWrapper alloc] init];
   onProgressBlocks.onProgressBlocks = [self.onProgressBlocks copy];
	
   settings.onSuccessBlocks = onSuccessBlocks;
   settings.onRejectBlocks = onRejectBlocks;
   settings.onProgressBlocks = onProgressBlocks;
	
   settings.chain = self.chain;
	
   SomePromiseSettingsResolvers *resolvers = [[SomePromiseSettingsResolvers alloc] init];
   resolvers.initBlock = self.initBlock;
   resolvers.futureBlock = self.futureBlock;
   resolvers.noFutureBlock = self.noFutureBlock;
	
   if([self isKindOfClass:[_SomeWhenPromise class]])
   {
	   _SomeWhenPromise *whenPromise  = (_SomeWhenPromise*)self;
	   resolvers.finalResultBlock = [whenPromise.finalResultBlock copy];
   }
	
   settings.resolvers = resolvers;
	
   SomePromiseSettingsObserverWrapper *observers = [[SomePromiseSettingsObserverWrapper alloc] init];
   observers.observers = self.observers;
   settings.observers = observers;

   settings.futureClass = self.future.currentClass;

   settings.resolved = (status != ESomePromiseSuccess && status != ESomePromiseRejected);

   return [settings copy];
}

- (id) result
{
      __block id value = nil;
      if(_statusPromiseQueue == nil)
         return _result;
      dispatch_sync(_statusPromiseQueue, ^
      {
		  value = self->_result;
      });
      return value;
}

- (NSError*) error
{
	__block id value = nil;
	if(_statusPromiseQueue == nil)
         return _error;

	dispatch_sync(_statusPromiseQueue, ^
	{
		value = self->_error;
    });
	return value;
}

- (id) ownerResult
{
      __block id value = nil;

      dispatch_sync(_statusPromiseQueue, ^
      {
		  value = self->_ownerResult;
      });
      return value;
}

- (NSError*) ownerError
{
	__block id value = nil;
	dispatch_sync(_statusPromiseQueue, ^
	{
		value = self->_ownerError;
    });
	return value;
}

- (void) setOwnerError:(NSError *)ownerError
{
   guard (ownerError) else {return;}
   dispatch_sync(_statusPromiseQueue, ^
   {
       self->_ownerError = ownerError;
   });
}

- (void) setOwnerResult:(id)ownerResult
{
   guard (ownerResult) else {return;}
   dispatch_sync(_statusPromiseQueue, ^
   {
       self->_ownerResult = ownerResult;
   });

}

- (float) progress
{
      if(!_statusPromiseQueue)
      {
         return _progress;
	  }
      __block float progress = 0;
      dispatch_sync(_statusPromiseQueue, ^
      {
		  progress = self->_progress;
      });
      return progress;
}

//Change procent.
- (void) setProgress:(float)progress
{
   if (progress < 0 || progress > 100 || !_statusPromiseQueue)
   {
      return;
   }

   __weak SomePromise *weakSelf = self;
   dispatch_sync(_statusPromiseQueue, ^
   {
      __strong SomePromise *strongSelf = weakSelf;
	  if (ESomePromisePending != strongSelf->_status)
      {
         return;
	  }
	   strongSelf->_progress = progress;
	  
	  if (strongSelf.delegate)
      {
        if(strongSelf.delegateThread)
        {
			[strongSelf.delegateThread performBlock:^{
		       if([strongSelf.delegate respondsToSelector:@selector(promise:progress:)])
		       {
				  [strongSelf.delegate promise: strongSelf progress:progress];
			   }
            }];
		}
		else
		{
		    dispatch_async(strongSelf.delegatePromiseQueue, ^
		    {
		       if([strongSelf.delegate respondsToSelector:@selector(promise:progress:)])
		       {
				  [strongSelf.delegate promise: strongSelf progress:progress];
			   }
		    });
		}
      }
	  for (id<SomePromiseObserver> observer in strongSelf.observers)
	  {
	        SomePromiseThread *thread =  [strongSelf.observers objectForKey:observer].thread;
	        if(thread)
	        {
			   [thread performBlock:^{
				   if([observer respondsToSelector:@selector(promise:progress:)])
		           {
				      [observer promise: strongSelf progress:progress];
			       }
               }];
			}
			else
			{
			   dispatch_async([strongSelf.observers objectForKey:observer].queue, ^
			   {
				   if([observer respondsToSelector:@selector(promise:progress:)])
		           {
				      [observer promise: strongSelf progress:progress];
			       }
			   });
			}
	   }
	   
	   for(OnProgressBlock progressblock in strongSelf.onProgressBlocks)
	   {
		  if(strongSelf.onHandlerThread == nil &&
			 strongSelf.onHandlerQueue == nil)
		  {
	          if(strongSelf.thread)
	          {
			     [strongSelf.thread performBlock:^{
                   progressblock(progress);
                 }];
		      }
		      else
		      {
		         dispatch_async(strongSelf.defaultPromiseQueue, ^
		         {
		          progressblock(progress);
		         });
			  }
			}
			else
			{
			  if(strongSelf.onHandlerThread)
	          {
			     [strongSelf.onHandlerThread performBlock:^{
                   progressblock(progress);
                 }];
		      }
		      else
		      {
		         dispatch_async(strongSelf.onHandlerQueue, ^
		         {
		          progressblock(progress);
		         });
			  }
			}
		}
   });
	
   [self.chain promise:self progress:progress];
}

- (void) ownerReleased
{
     NSError *error = rejectionErrorWithText(@"Owner Relesed", ESomePromiseError_OwnerReleased);
     [self rejectWithError:error];
}

- (void) ownerDoneWithResult:(id) result
{
	self.agent = self;
	__weak SomePromise *weakSelf = self;
	//check if Promise is rejected.
	
	if (ESomePromisePending == self.status)
	{
		__strong SomePromise *strongSelf = weakSelf;
		if(!strongSelf)
			return;
	    strongSelf.ownerResult = result;
	    if(_thread)
	    {
		   [_thread performBlock:^{
              strongSelf.futureBlock(strongSelf.fulfillBlock, strongSelf.rejectBlock, strongSelf.isRejectedBlock, strongSelf.progressBlock, result, strongSelf.chain);
           }];
		}
		else
		{
           dispatch_async(_defaultPromiseQueue, ^
           {
	          strongSelf.futureBlock(strongSelf.fulfillBlock, strongSelf.rejectBlock, strongSelf.isRejectedBlock, strongSelf.progressBlock, result, strongSelf.chain);
           });
		}
	 }
	 else
	 {
	    self.agent = nil;
	 }
}

- (void) ownerFailedWithError:(NSError*) error
{
	self.agent = self;
	__weak SomePromise *weakSelf = self;
	//check if Promise is rejected.
	
	if (ESomePromisePending == self.status)
	{
		__strong SomePromise *strongSelf = weakSelf;
		if(!strongSelf)
			return;
	    strongSelf.ownerError = error;
	    if(_thread)
	    {
		   [_thread performBlock:^{
			  strongSelf.noFutureBlock(strongSelf.fulfillBlock, strongSelf.rejectBlock, strongSelf.isRejectedBlock, strongSelf.progressBlock, error, strongSelf.chain);
           }];
		}
		else
		{
           dispatch_async(_defaultPromiseQueue, ^
           {
	          strongSelf.noFutureBlock(strongSelf.fulfillBlock, strongSelf.rejectBlock, strongSelf.isRejectedBlock, strongSelf.progressBlock, error, strongSelf.chain);
           });
		}
	 }
	 else
	 {
	    self.agent = nil;
	 }
}

static void startSubpromise(SomePromiseSettings* settings, FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejected, ProgressBlock progressBlock, NSError *error, NSInteger maxRetryAmount, BOOL (^condition)(void))
{
    if(condition)
    {
	   guard(condition() && !isRejected()) else {rejectBlock(error); return;}
	}
	else
	{
       guard(maxRetryAmount > 0 && !isRejected()) else {rejectBlock(error); return;}
	}
    SomePromise *retryPromise = [SomePromise promiseWithSettings:settings];
	retryPromise.onSuccess(^(id value){
	   fulfillBlock(value);
	});
    retryPromise.subRejectBlock = rejectBlock;
    retryPromise.onReject(^(NSError *error){
	   startSubpromise(settings, fulfillBlock, rejectBlock, isRejected, progressBlock,  error, maxRetryAmount == NSIntegerMax ? maxRetryAmount : maxRetryAmount - 1, condition);
	}).onProgress(^(float progress){
		progressBlock(progress);
	});
}

- (SomePromise*)_retryWithNumbers:(NSInteger)maxRetryAmount condition:(BOOL (^ _Nullable)(void))condition
{
   SomePromiseSettings* settings = [self.settings freshCopy];
   NoFutureBlock nfB = ^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *error, id<SomePromiseLastValuesProtocol>lastValuesInChain)
        {
            if(!condition)
            {
	           guard(maxRetryAmount > 0) else {rejectBlock(error); return;}
			}
			else
			{
			   guard(condition()) else {rejectBlock(error); return;}
			}
			startSubpromise(settings, fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, maxRetryAmount, condition);
		};

    if(self.promiseThread)
    {
        return [SomePromise promiseWithName:self.name dependentOn:self onThread:self.thread onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejected, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValues)
        {
	        fulfillBlock(result);
        } onReject:nfB
		     class:self.future.currentClass];
	}
	else
	{
        return [SomePromise promiseWithName:self.name dependentOn:self onQueue:self.promiseQueue onSuccess:^(FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejected, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValues)
        {
	        fulfillBlock(result);
        } onReject:nfB
             class:self.future.currentClass];
    }
}

- (SomePromise*)retryWithNumbers:(NSInteger)maxRetryAmount
{
   return [self _retryWithNumbers:maxRetryAmount condition:nil];
}

- (SomePromise*)retryWhileCondition:(BOOL (^ _Nonnull)(void))condition
{
   return [self _retryWithNumbers:0 condition:[condition copy]];
}

- (SomePromise*)retryOnce
{
    return [self retryWithNumbers:1];
}

- (SomePromise*)retryInfinity
{
   return [self retryWithNumbers:NSIntegerMax];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSInteger))retry
{
	__weak SomePromise *weakSelf = self;
	return [^SomePromise*(NSInteger number)
	{
		__strong SomePromise *strongSelf = weakSelf;
		return [strongSelf retryWithNumbers:number];
	} copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(BOOL (^ _Nonnull)(void)))retryWhile
{
	__weak SomePromise *weakSelf = self;
	return [^SomePromise*(BOOL (^condition)(void))
	{
		__strong SomePromise *strongSelf = weakSelf;
		return [strongSelf retryWhileCondition:condition];
	} copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(OnSuccessBlock _Nonnull)) onSuccess
{
    __weak SomePromise *weakSelf = self;
    SomePromise*(^successBlock)(OnSuccessBlock) = ^SomePromise*(OnSuccessBlock block)
    {
		__strong SomePromise *strongSelf = weakSelf;
       return [strongSelf onSuccess: block];
    };
	
    return [successBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(OnRejectBlock _Nonnull)) onReject
{
    __weak SomePromise *weakSelf = self;
    SomePromise*(^rejectBlock)(OnRejectBlock) = ^SomePromise*(OnRejectBlock block)
    {
		__strong SomePromise *strongSelf = weakSelf;
       return [strongSelf onReject: block];
    };
	
    return [rejectBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(OnProgressBlock _Nonnull)) onProgress
{
    __weak SomePromise *weakSelf = self;
    SomePromise*(^progressBlock)(OnProgressBlock) = ^SomePromise*(OnProgressBlock block)
    {
		__strong SomePromise *strongSelf = weakSelf;
       return [strongSelf onProgress: block];
    };
	
    return [progressBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(onEachSuccessBlock _Nonnull))onEachSuccess
{
    __weak SomePromise *weakSelf = self;
    SomePromise*(^successBlock)(onEachSuccessBlock) = ^SomePromise*(onEachSuccessBlock block)
    {
		__strong SomePromise *strongSelf = weakSelf;
       return [strongSelf onEachSuccess: block];
    };
	
    return [successBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(OnEachRejectBlock _Nonnull))onEachReject
{
    __weak SomePromise *weakSelf = self;
    SomePromise*(^rejectBlock)(OnEachRejectBlock) = ^SomePromise*(OnEachRejectBlock block)
    {
		__strong SomePromise *strongSelf = weakSelf;
       return [strongSelf onEachReject: block];
    };
	
    return [rejectBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(OnEachProgressBlock _Nonnull))onEachProgress
{
    __weak SomePromise *weakSelf = self;
    SomePromise*(^progressBlock)(OnEachProgressBlock) = ^SomePromise*(OnEachProgressBlock block)
    {
		__strong SomePromise *strongSelf = weakSelf;
       return [strongSelf onEachProgress: block];
    };
	
    return [progressBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))addObserver
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(id<SomePromiseObserver>) = ^SomePromise*(id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObserver:observer];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, id<SomePromiseObserver> _Nonnull))addObserverOnQueue
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(dispatch_queue_t, id<SomePromiseObserver>) = ^SomePromise*(dispatch_queue_t queue, id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObserver:observer onQueue:queue];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, id<SomePromiseObserver> _Nonnull))addObserverOnThread
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(SomePromiseThread *, id<SomePromiseObserver>) = ^SomePromise*(SomePromiseThread *thread, id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObserver:observer onThread:thread];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))addObserverOnMain
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(id<SomePromiseObserver>) = ^SomePromise*(id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObserverOnMain:observer];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSArray<id<SomePromiseObserver>> *_Nonnull))addObservers
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(NSArray<id<SomePromiseObserver>> *) = ^SomePromise*(NSArray<id<SomePromiseObserver>> * observers)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObservers:observers];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnMain
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(NSArray<id<SomePromiseObserver>> *) = ^SomePromise*(NSArray<id<SomePromiseObserver>> * observers)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObserversOnMain:observers];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnQueue
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(dispatch_queue_t, NSArray<id<SomePromiseObserver>> *) = ^SomePromise*(dispatch_queue_t queue, NSArray<id<SomePromiseObserver>> * observers)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObservers:observers onQueue:queue];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnThread
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(SomePromiseThread *, NSArray<id<SomePromiseObserver>> *) = ^SomePromise*(SomePromiseThread *thread, NSArray<id<SomePromiseObserver>> * observers)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addObservers:observers onThread:thread];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))removeObserver
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^removeObserverBlock)(id<SomePromiseObserver>) = ^SomePromise*(id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf removeObserver:observer];
   };
	
   return [removeObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(void))removeAllObservers
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^removeObserversBlock)(void) = ^SomePromise*(void)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf removeObservers];
   };
	
   return [removeObserversBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, id<SomePromiseObserver> _Nonnull))addChainObserverOnThread
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(SomePromiseThread*, id<SomePromiseObserver>) = ^SomePromise*(SomePromiseThread *thread, id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addChainObserver:observer onThread:thread];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, id<SomePromiseObserver> _Nonnull))addChainObserver
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^addObserverBlock)(dispatch_queue_t, id<SomePromiseObserver>) = ^SomePromise*(dispatch_queue_t queue, id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf addChainObserver:observer onQueue:queue];
   };
	
   return [addObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))removeChainObserver
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^removeObserverBlock)(id<SomePromiseObserver>) = ^SomePromise*(id<SomePromiseObserver> observer)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf removeChainObserver:observer];
   };
	
   return [removeObserverBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(void))removeAllObserversinChain
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^removeObserversBlock)(void) = ^SomePromise*(void)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf removeChainObservers];
   };
	
   return [removeObserversBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread*_Nullable))setChainThread
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^setChainThreadBlock)(SomePromiseThread*) = ^SomePromise*(SomePromiseThread *thread)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf setChainThread:thread];
   };
	
   return [setChainThreadBlock copy];
}

- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable))setChainQueue
{
   __weak SomePromise *weakSelf = self;
   SomePromise*(^setChainQueueBlock)(dispatch_queue_t) = ^SomePromise*(dispatch_queue_t queue)
   {
      __strong SomePromise *strongSelf = weakSelf;
      return [strongSelf setChainQueue:queue];
   };
	
   return [setChainQueueBlock copy];
}

+ (void) load
{
   static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		
	   __internalTimeoutThread = [SomePromiseThread threadWithName:@"InternalSomePromiseTimeoutsTimerThread"];
		
	   [SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(SomePromiseChainMethods) extention:[SomePromiseChainMethodsExecutorStrategy class] whereSelf:@protocol(SomePromiseChainMethodsExecutorStrategyUser)];
		
	   [SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(SomePromiseChainPropertyMethods) extention:[SomePromiseChainMethodsExecutorStrategy class] whereSelf:@protocol(SomePromiseChainMethodsExecutorStrategyUser)];
		
	   //swizzling stop with internalSomePromiseStop (SomePromiseThread)
	   Class class = [SomePromiseThread class];
		
	   SEL originalSelector = @selector(stop);
	   SEL swizzledSelector = @selector(internalSomePromiseStop);
		
		Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
		
        BOOL didAddMethod =
            class_addMethod(class,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

@end

//-----------------------------------------------

@implementation _SomeWhenPromise

@synthesize firstFulfillBlock = _firstFulfillBlock;
@synthesize firstRejectBlock = _firstRejectBlock;
@synthesize selfError = _selfError;
@synthesize selfResult = _selfResult;
@synthesize ownerResolved = _ownerResolved;
@synthesize selfResolved = _selfResolved;
@synthesize finalResultBlock = _finalBlock;

- (instancetype) initWithSettings:(SomePromiseSettings*)settings
{
   self = [super initWithSettings:settings];
   self.finalResultBlock = settings.resolvers.finalResultBlock;
   self.ownerResolved = YES;
   return self;
}

- (instancetype) initWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							      onChain:(_InternalChainHandler* _Nonnull) chain
								   thread:(SomePromiseThread* _Nullable) thread
						   delegateThread:(SomePromiseThread* _Nullable) delegateThread
						            class:(Class _Nullable)class
{
    self = [super initWithName: name
                         block: initBlock
                         queue: queue
					  delegate: delegate
				 delegateQueue: delegateQueue
				    postPonded: YES
				       onChain: chain
						thread: thread
				delegateThread: delegateThread
				         class: class];
	
	if (self)
	{
	   [ownerPromise privateAddWhen:self];
	   _finalBlock = [finalBlock copy];
		
	   if (ESomePromisePending == ownerPromise.status)
	   {
	      [self start];
	   }
	}
	
    return self;
}

- (void) templateMethodStart
{
   self.initBlock(self.firstFulfillBlock, self.firstRejectBlock, self.isRejectedBlock, self.progressBlock);
}

- (void) startFinalBlock
{
     if(self.thread)
     {
	     [self.thread performBlock:^{
			self->_finalBlock(self.fulfillBlock, self.rejectBlock, self.isRejectedBlock, self.progressBlock, self.ownerResult, self.selfResult, self.ownerError, self.selfError, self.chain);
         }];
	 }
	 else
	 {
        dispatch_async(self.defaultPromiseQueue, ^
        {
		   self->_finalBlock(self.fulfillBlock, self.rejectBlock, self.isRejectedBlock, self.progressBlock, self.ownerResult, self.selfResult, self.ownerError, self.selfError, self.chain);
	    });
	 }
}

- (void) prepareInternalBlocks
{
   [super prepareInternalBlocks];
   __weak _SomeWhenPromise *weakSelf = self;
   self.firstFulfillBlock = ^void(id object)
   {
        __strong _SomeWhenPromise *strongSelf = weakSelf;
        __block BOOL startFinalBlock = NO;
		dispatch_sync(strongSelf.statusPromiseQueue, ^
        {
			strongSelf.selfResult = object;
			strongSelf.selfResolved = YES;
			if (strongSelf.ownerResolved)
			{
			   startFinalBlock = YES;
			}
        });
        if (startFinalBlock)
        {
           [strongSelf startFinalBlock];
		}
   };
	
   self.firstRejectBlock = ^void(NSError *error)
   {
        __strong _SomeWhenPromise *strongSelf = weakSelf;
        __block BOOL startFinalBlock = NO;
		dispatch_sync(strongSelf.statusPromiseQueue, ^
        {
			strongSelf.selfError = error;
			strongSelf.selfResolved = YES;
			if (strongSelf.ownerResolved)
			{
			   startFinalBlock = YES;
			}
        });
        if (startFinalBlock)
        {
           [strongSelf startFinalBlock];
		}
   };
}

- (void) ownerFinishedWith:(id _Nullable) result error:(NSError* _Nullable) error
{
        __block BOOL startFinalBlock = NO;
		dispatch_sync(self.statusPromiseQueue, ^
        {
            self->_ownerError = error;
            self->_ownerResult = result;
            self.ownerResolved = YES;
			
            if (self.selfResolved)
            {
				startFinalBlock = YES;
			}
        });
	
		if (startFinalBlock)
        {
           [self startFinalBlock];
		}
}

@end

@implementation SomePromise(friend)

- (void) addProvider:(id)provider
{
   [_providers addObject:provider];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegateThread
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: queue
									  delegate: delegate
								 delegateQueue: nil
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: chain
										thread: nil
							    delegateThread: delegateThread
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: queue
									  delegate: delegate
								 delegateQueue: delegateQueue
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: chain
										thread: nil
							    delegateThread: nil
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegateThread
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
								    class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: nil
									  delegate: delegate
								 delegateQueue: nil
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: chain
										thread: thread
							    delegateThread: delegateThread
							             class: class];
}

+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
							  dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								onSuccess:(FutureBlock _Nonnull ) futureBlock
								 onReject:(NoFutureBlock _Nullable ) errorBlock
								  onChain:(_InternalChainHandler* _Nullable) chain
									class:(Class _Nullable)class
{
	return   [[SomePromise alloc] initWithName: name
								   dependendOn: ownerPromise
									   onQueue: nil
									  delegate: delegate
								 delegateQueue: delegateQueue
									 onSuccess: futureBlock
									  onReject: errorBlock
									   onChain: chain
										thread: thread
							    delegateThread: nil
							             class: class];
}

@end
