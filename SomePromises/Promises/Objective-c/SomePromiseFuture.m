//
//  SomePromiseFuture.m
//  SomePromises
//
//  Created by Sergey Makeev on 23/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseFuture.h"
#import "SomePromise.h"
#import "SomePromiseThread.h"
#import "SomePromiseChainMethodsExecutorStrategy.h"
#import "SomePromiseUtils.h"
#import <objc/runtime.h>

@interface SomePromiseFuture(share_to_promise)

- (instancetype _Nonnull) initInternalWithClass:(Class _Nullable)class owner:(SomePromise *_Nonnull) promise;
- (void) internalResolveWithObject:(id _Nonnull)object;
- (void) internalResolveWithError:(NSError *_Nullable)error;

@end

@interface SomePromiseFuture()
{
    SomeClassBox *_object;
    SomeClassBox<NSError*> *_error;
    BOOL _resolved;

    dispatch_queue_t _queue;
    SomePromiseThread *_thread;
	
	BOOL _stopped; //if resolved and tasks stopped (was in progress)
	BOOL _inProgress; //if resolved and tasks in progress;
    NSMutableArray *_tasks; //invocations

	NSMutableArray<id<DependentPromiseProtocol> > *_dependantPromises;
	NSMutableArray<id<WhenPromiseProtocol> > *_whenPromises;

   __weak SomePromise *_owner;
}
@property (nonatomic, readonly) NSCondition* condition;

@end

@implementation SomePromiseFuture

+ (void) load
{
   static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
	   [SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(SomePromiseChainMethods) extention:[SomePromiseChainMethodsExecutorStrategy class] whereSelf:@protocol(SomePromiseChainMethodsExecutorStrategyUser)];
	   [SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(SomePromiseChainPropertyMethods) extention:[SomePromiseChainMethodsExecutorStrategy class] whereSelf:@protocol(SomePromiseChainMethodsExecutorStrategyUser)];
    });
}

- (void) checkSelf
{
   if (!_thread && !_queue)
   {
      _queue = dispatch_queue_create("SomePromisesFutureQueue", DISPATCH_QUEUE_SERIAL);
   }
   if(!_tasks)
   {
      _tasks = [NSMutableArray new];
   }
   if(!_dependantPromises)
   {
      _dependantPromises = [NSMutableArray array];
   }
   if(!_whenPromises)
   {
	  _whenPromises = [NSMutableArray array];
   }
   if(!self.currentClass)
   {
      self.currentClass = [NSObject class];
   }
}


- (instancetype _Nonnull) init
{
   if(self)
   {
       [self initCondition];
       _queue = dispatch_queue_create("SomePromisesFutureQueue", DISPATCH_QUEUE_SERIAL);
       _tasks = [NSMutableArray new];
	   _dependantPromises = [NSMutableArray array];
	   _whenPromises = [NSMutableArray array];
   }
   [self checkSelf];
   return self;
}

- (void) initCondition
{
    _condition = [[NSCondition alloc] init];
    _object = [SomeClassBox empty];
    _error = [SomeClassBox<NSError*> empty];
}

- (instancetype _Nonnull) initWithClass:(Class _Nullable)class
{
   self = [self init];
   if(self)
   {
       [self initCondition];
       self.currentClass = class;
   }
   [self checkSelf];
   return self;
}

- (instancetype _Nonnull) initWithQueue:(dispatch_queue_t _Nullable)queue  class:(Class _Nullable)class
{
   if(self)
   {
	   [self initCondition];
       _queue = queue;
       self.currentClass = class;
       _tasks = [NSMutableArray new];
	   _dependantPromises = [NSMutableArray array];
	   _whenPromises = [NSMutableArray array];
   }
   [self checkSelf];
   return self;
}

- (instancetype _Nonnull) initWithThread:(SomePromiseThread *_Nullable)thread  class:(Class _Nullable)class
{
   if(self)
   {
       [self initCondition];
       _thread = thread;
       self.currentClass = class;
       _tasks = [NSMutableArray new];
	   _dependantPromises = [NSMutableArray array];
   }
   [self checkSelf];
   return self;
}

- (instancetype _Nonnull) initInternalWithClass:(Class _Nullable)class owner:(SomePromise *_Nonnull) promise
{
     if(self)
     {
       [self initCondition];
       _owner = promise;
       self.currentClass = class;
       _tasks = [NSMutableArray new];
	   _dependantPromises = [NSMutableArray array];
	 }
	 [self checkSelf];
	 return self;
}

- (void) internalResolveWithObject:(id _Nonnull)object
{
   @synchronized(self)
   {
     if(!_resolved)
     {
       [_condition signal];
	   _object.value = object;
	   _resolved = YES;
	   _inProgress = YES;
	   for (id<DependentPromiseProtocol> dependee in _dependantPromises)
	   {
		  [dependee ownerDoneWithResult:_object.value];
	   }
	   [_dependantPromises removeAllObjects];
		 
	   for (id<WhenPromiseProtocol> whenPromise in _whenPromises)
	   {
		  [whenPromise ownerFinishedWith:_object.value error:nil];
	   }
	   [self startTasks];
	 }
   }
}

- (void) resolveWithObject:(id _Nonnull)object
{
   if(_owner != nil)
   {
      NSLog(@"Some Promise Warning!, try to resolve future beholding to Promise not from the owner promise!");
      return;
   }
	
   [self internalResolveWithObject:object];
}

- (void) internalResolveWithError:(NSError *_Nullable)error
{
   @synchronized(self)
   {
     if(!_resolved)
     {
      _error.value = error;
      _resolved = YES;
      [_tasks removeAllObjects];
      _tasks = nil;
	   for (id<DependentPromiseProtocol> dependee in _dependantPromises)
	   {
		  [dependee ownerFailedWithError:_error.value];
	   }
	   [_dependantPromises removeAllObjects];
		 
	   for (id<WhenPromiseProtocol> whenPromise in _whenPromises)
	   {
		  [whenPromise ownerFinishedWith:nil error:_error.value];
	   }
	 }
   }
}

- (void) resolveWithError:(NSError *_Nullable)error
{
   if(_owner != nil)
   {
      NSLog(@"Some Promise Warning!, try to resolve future beholding to Promise not from the owner promise!");
      return;
   }
	
   [self internalResolveWithError:error];
}

- (void) startTasks
{
   for (NSInvocation *invocation in _tasks)
   {
	   BOOL shouldInvoke = YES;
	   @synchronized(self)
       {
		   shouldInvoke = !_stopped;
       }
       if(shouldInvoke)
       {
           @synchronized(self)
           {
              if(_thread)
              {
                 [_thread performBlock:^{
		            [invocation invokeWithTarget:self->_object.value];
		         }];
		      }
		      else
		      {
			     dispatch_async(_queue, ^
			     {
		            [invocation invokeWithTarget:self->_object.value];
				  });
		      }
			}
	   }
	   else
	   {
	     return;
	   }
   }
}

- (BOOL) isResolved
{
   BOOL resolved = NO;
   @synchronized(self)
   {
      resolved = _resolved;
   }
   return resolved;
}

- (BOOL) hasError
{
   BOOL isError = NO;
   @synchronized(self)
   {
      if(_error.value != nil)
      {
         isError = YES;
	  }
   }
   return isError;
}

- (BOOL) hasResult
{
   BOOL isResult = NO;
   @synchronized(self)
   {
      if(_object.value != nil)
      {
         isResult = YES;
	  }
   }
   return isResult;
}

- (id _Nullable) getFuture
{
   id result = nil;
   @synchronized(self)
   {
      if(!_resolved)
      {
         result = self;
	  }
	  else
	  {
	     if(_error.value != nil)
	     {
	        result = nil;
		 }
		 else
		 {
		    result = _object.value;
		 }
	  }
   }
   return result;
}

- (NSError *_Nullable) getError
{
   NSError *error = nil;
   @synchronized(self)
   {
      error = _error.value;
   }
   return error;
}

- (void (^ __nonnull)(id _Nonnull, void (^SPListener)(id _Nullable)))bind
{
    return _object.bind;
}

- (void (^ __nonnull)(id _Nonnull, void (^SPListener)(NSError *_Nullable)))bindError
{
    return _error.bind;
}

- (void) unbind:(id _Nonnull )object
{
   [_object unbind:object];
}

- (void) unbindError:(id _Nonnull )object
{
   [_error unbind:object];
}

- (void) addValueListener:(SomeListener *_Nonnull)listener
{
    [listener listenTo:_object];
}

- (void) removeValueListener:(SomeListener *_Nonnull)listener
{
   [listener stopListenTo:_object];
}

- (void) addErrorListener:(SomeListener *_Nonnull)listener
{
   [listener listenTo:_error];
}

- (void) removeErrorListener:(SomeListener *_Nonnull)listener
{
   [listener stopListenTo:_error];
}

- (id _Nullable) get
{
    id result = [self getFuture];
    guard (result == self) else { return result; }
    //if result == self future is not resolved yet.
	while(!self.isResolved)
	{
	   [_condition wait];
	}
	result = [self getFuture];
	return result ? : [self getError];
}

- (dispatch_queue_t _Nullable) queue
{
   dispatch_queue_t queueToReturn = nil;
   @synchronized(self)
   {
      queueToReturn = _queue;
   }

   return queueToReturn;
}

- (SomePromiseThread *_Nullable) thread
{
   SomePromiseThread *threadToReturn = nil;
   @synchronized(self)
   {
      threadToReturn = _thread;
   }

   return threadToReturn;
}

- (void) stopAllTasks
{
   @synchronized(self)
   {
      if(_inProgress)
      {
         _stopped = YES;
	  }
   }
}

- (void) setQueue:(dispatch_queue_t _Nonnull) queue
{
   @synchronized(self)
   {
	  _queue = queue;
	  _thread = nil;
   }
}

- (void) setThread:(SomePromiseThread *_Nonnull) thread
{
   @synchronized(self)
   {
	   _thread = thread;
	   _queue = nil;
   }
}

- (PromiseStatus) status
{
   PromiseStatus _status = ESomePromiseUnknown;
   @synchronized(self)
   {
      if(!_resolved)
      {
		  _status = ESomePromisePending;
	  }
	  else if(_object)
	  {
	      _status = ESomePromiseSuccess;
	  }
	  else
	  {
	      _status = ESomePromiseRejected;
	  }
   }
   return _status;
}

//NSProxy:

- (NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{
    if(self.currentClass == nil)
    {
       return nil;
	}
	return [_currentClass instanceMethodSignatureForSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
    if(self.currentClass == nil)
    {
       return;
	}
	@synchronized(self)
	{
	   if(_inProgress || _stopped || _resolved) return;
	
       const char* returnType = [invocation.methodSignature methodReturnType];
		
	   if (returnType[0] == _C_CONST) returnType++;
	   if (strcmp(returnType, @encode(void)) != 0 )
	   {
		   NSLog(@"SomePromise Warning: Future object used for calling method with not void return type.");
	   }
		
	   [_tasks addObject:invocation];
	}
}

- (void) privateAddToDependancy:(id<DependentPromiseProtocol>) dependee
{
	if (ESomePromisePending == self.status)
    {
	   @synchronized(self)
	   {
	      [_dependantPromises addObject:dependee];
	   }
	}
	else
	{
	   id result = [self getFuture];
	   if (ESomePromiseSuccess == self.status)
	   {
	      [dependee ownerDoneWithResult:result];
	   }
	   else
	   {
		  [dependee ownerFailedWithError:result];
	   }
	}
}

- (void) rejectAllDependences
{
	@synchronized(self)
	{
       for (SomePromise *dependee in _dependantPromises)
       {
		 [dependee rejectAllInChain];
	   }
	
	   [_dependantPromises removeAllObjects];
		
	   for (SomePromise *when in _whenPromises)
	   {
	      [when rejectAllInChain];
	   }
		
	   [_whenPromises removeAllObjects];
	}
}

- (void) privateAddWhen:(id<WhenPromiseProtocol>) when
{
 	@synchronized(self)
	{
		[_whenPromises addObject:when];
	}
}

//Promises:

- (SomePromise*) addPromiseWithName:(NSString*)name success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							    onQueue:queue
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   onThread:thread
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   delegate:delegate
						  delegateQueue:nil
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							    onQueue:queue
							   delegate:delegate
						  delegateQueue:nil
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   onThread:thread
							   delegate:delegate
						  delegateQueue:nil
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   delegate:delegate
						  delegateQueue:delegateQueue
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   delegate:delegate
						 delegateThread:delegateThread
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							    onQueue:queue
							   delegate:delegate
						  delegateQueue:delegateQueue
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   onThread:thread
							   delegate:delegate
						 delegateThread:delegateThread
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate ddelegateThread:(SomePromiseThread *_Nullable)delegateThread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							    onQueue:queue
							   delegate:delegate
						 delegateThread:delegateThread
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class
{
    return [SomePromise promiseWithName:name
							dependentOn:self
							   onThread:thread
							   delegate:delegate
						  delegateQueue:delegateQueue
					          onSuccess:futureBlock
						       onReject:rejectedBlock
						          class: class];
}

//when promises

- (SomePromise*) addWhenPromiseWithName:(NSString*)name resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
						       onQueue:queue
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							  onThread:thread
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							  delegate:delegate
						 delegateQueue:nil
							 resolvers:initBlock
						   finalResult:finalBlock
								 class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
						       onQueue:queue
							  delegate:delegate
						 delegateQueue:nil
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							 onThread:thread
							  delegate:delegate
						 delegateQueue:nil
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							  delegate:delegate
						 delegateQueue:delegateQueue
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							  delegate:delegate
						delegateThread:delegateThread
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
                               onQueue:queue
							  delegate:delegate
						 delegateQueue:delegateQueue
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							  onThread:thread
							  delegate:delegate
						delegateThread:delegateThread
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];

}


- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
                               onQueue:queue
							  delegate:delegate
						delegateThread:delegateThread
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];
}

- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class
{
   return [SomePromise promiseWithName:name
						   whenPromise:self
							  onThread:thread
							  delegate:delegate
						 delegateQueue:delegateQueue
							 resolvers:initBlock
						   finalResult:finalBlock
						         class: class];

}

- (id _Nullable) lastResultInChain
{
   return nil;
}

-  (NSError *_Nullable) lastErrorInChain
{
   return nil;
}


- (_InternalChainHandler*)chain
{
   return nil;
}

- (SomePromiseThread*)delegateThread
{
   return nil;
}

-(NSString *_Nonnull) name
{
   return @"SomePromiseFutureObject";
}

- (id<SomePromiseDelegate>) delegate
{
   return nil;
}

- (dispatch_queue_t) delegatePromiseQueue
{
   return nil;
}

@end
