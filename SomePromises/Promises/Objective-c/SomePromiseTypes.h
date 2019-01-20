//
//  SomePromiseTypes.h
//  SomePromises
//
//  Created by Sergey Makeev on 25/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//


/****************************************************************************************************************
*	SomePromiseTypes.h provides  some types used in the lib
*	some protocols, blocks, defines, enums and functions.
*	Provides the most part of #PROMISE_HELPER methods.
****************************************************************************************************************/
#ifndef SomePromiseTypes_h
#define SomePromiseTypes_h

/****************************************************************************************************************
*	@sp_weakly(id object)
*	returns weak wrapper for object to be stored in SPArray as weak.
*	Is used to mark stored in SPArray element as weak
*	ex:
* 	SPArray<TestSPArrayElement*> *array = [SPArray fromArray: @[el1, el2, @sp_weakly(el3)]];
*	el3 is stored weakly.
****************************************************************************************************************/
#define sp_weakly(a) "should be called with @".length ? [[__SPArrayElementWrapperWeak alloc] initWithValue:a] : nil

//create SPPair
#define sp_pair(left, riht) "Should be called with @" @"".length ? [SPPair pairWithLeft:left right:right] : nil

@class SomePromiseThread;
@class SomePromiseSettingsPromiseWorker;
@class SomeProgressBlockProvider;
@class SomeIsRejectedBlockProvider;
@class SomePromiseSettingsPromiseDelegateWorker;
@class SomeResultProvider;
@class SomeValuesInChainProvider;
@class SomeParameterProvider;
typedef SomePromiseSettingsPromiseWorker* PromiseWorker;
typedef SomePromiseSettingsPromiseDelegateWorker* DelegateWorker;

//Following functions are used inside #PROMISE_HELPER to provide providers.
//Providers are objects that provides services to the promise such as thread/queue for action and delegate
//Previous promises results.
//Promise's action's blocks (progress, isRejected) and so on.
//Just call this function in place of value for relative parameter. Provider will get value itself.
//You need only create in calling this function
// ex:
//	spTry(^(PromiseWorker worker, SomeIsRejectedBlockProvider *isRejected)
//	{
//		if(isRejected.isRejectedBlock())
//		{
//        return 0;
//	 	}
//		return 3;
//	}, promiseWorkerWithName(@"Test worker thread"), isRejectedProvider());
/****************************************************************************************************************
*	PromiseWorker promiseWorker(SomePromiseThread *thread);
*	returns SomePromiseSettingsPromiseWorker wrapper on SomePromiseThread
*	Note!: You don't need to use it inside the promise action.
*	It will be working in provided thread automatically
****************************************************************************************************************/
PromiseWorker promiseWorker(SomePromiseThread *thread);

/****************************************************************************************************************
*	PromiseWorker promiseWorkerWithName(NSString *name);
*	returns SomePromiseSettingsPromiseWorker wrapper on SomePromiseThread with name.
*	hread is created by provided name.
*	Note!: You don't need to use it inside the promise action.
*	It will be working in provided thread automatically
****************************************************************************************************************/
PromiseWorker promiseWorkerWithName(NSString *name);

/****************************************************************************************************************
*	PromiseWorker promiseWorkerWithQueue(dispatch_queue_t queue);
*	returns queue provider for promise
*	Note!: You don't need to use it inside the promise action.
*	It will be working in provided queue automatically
****************************************************************************************************************/
PromiseWorker promiseWorkerWithQueue(dispatch_queue_t queue);

/****************************************************************************************************************
*	DelegateWorker delegateWorker(SomePromiseThread *thread)
*	returns thread provider for promise delegate
****************************************************************************************************************/
DelegateWorker delegateWorker(SomePromiseThread *thread);

/****************************************************************************************************************
*	DelegateWorker delegateWorker(SomePromiseThread *thread)
*	returns thread provider created using name for promise delegate
****************************************************************************************************************/
DelegateWorker delegateWorkerWithName(NSString *name);

/****************************************************************************************************************
*	DelegateWorker delegateWorkerWithQueue(dispatch_queue_t queue)
*	returns queue provider for promise delegate
****************************************************************************************************************/
DelegateWorker delegateWorkerWithQueue(dispatch_queue_t queue);

/****************************************************************************************************************
*	SomeProgressBlockProvider* progressProvider(void)
*	returns progressProvider providing progress block to be called in promise action
*	to present current promise progress.
* 	ex:
//  spTry(^(SomeIsRejectedBlockProvider *isRejected, SomeProgressBlockProvider *progress){
//
//  for (int i = 0; i < 100; ++i)
//  {
//     if(isRejected.isRejectedBlock())
//     {
//        return 0;
//	 }
//	 else
//	 {
//	    sleep(1);
//	    progress.progressBlock(i);
//	 }
//  }
//
//  return 3;
//  }, isRejectedProvider(), progressProvider()).onProgress(^(float progress){NSLog(@"Progress: %f", progress);}).onSuccess(^(id result){ NSLog(@"Success: %@", result);}).onReject(^(NSError *error){ NSLog(@"Rejected");});
****************************************************************************************************************/
SomeProgressBlockProvider* progressProvider(void);


/****************************************************************************************************************
*	SomeParameterProvider* parameterProvider(id value);
*	returns parameter provider with value as a parameter value.
* 	also it can be a weak parameter.
****************************************************************************************************************/
SomeParameterProvider* parameterProvider(id value);
SomeParameterProvider* weakParameterProvider(id value);
/****************************************************************************************************************
*	SomeIsRejectedBlockProvider* isRejectedProvider(void)
*	returns isRejected block provider. ex above.
****************************************************************************************************************/
SomeIsRejectedBlockProvider* isRejectedProvider(void);

/****************************************************************************************************************
*	SomeResultProvider* resultProvider(void)
*	returns resultProvider for dependant promise.
****************************************************************************************************************/
SomeResultProvider* resultProvider(void);

/****************************************************************************************************************
*	SomeValuesInChainProvider* valuesProvider(void)
*	returns provider for values in chain.
****************************************************************************************************************/
SomeValuesInChainProvider* valuesProvider(void);

@protocol SomePromiseLastValuesProtocol;
@protocol SomePromiseChainMethodsExecutorStrategyUser;
@class SomePromiseThread;

/****************************************************************************************************************
*	enum SomePromiseErrors
*	provides some standard error codes
*	ESomePromiseError_Unknown - unknown error
*	ESomePromiseError_UserRejected - rejected called outside (without error)
*	ESomePromiseError_ThreadStopped - promise thread has been stopped.
*	ESomePromiseError_Timeout - Promise timeout.
*	ESomePromiseError_OwnerReleased - owner of the promise released before starting this promise.
*	ESomePromiseError_FromException - error got from exception inside the promise actio block.
*	ESomePromiseError_ConditionReturnsFalse - condition of spNext, spIf or spCatch is false.
****************************************************************************************************************/
typedef NS_ENUM(NSUInteger, SomePromiseErrors)
{
    ESomePromiseError_Unknown = 0,
	ESomePromiseError_UserRejected = 1,
	ESomePromiseError_ThreadStopped = 2,
	ESomePromiseError_Timeout = 3,
	ESomePromiseError_OwnerReleased = 4,
	ESomePromiseError_FromException = 5,
	ESomePromiseError_ConditionReturnsFalse = 6,
};

/****************************************************************************************************************
*	WhenPromiseProtocol. Usually you don't need it. Is needed mostly inside the lib.
*****************************************************************************************************************/
@protocol WhenPromiseProtocol <NSObject>
@required
- (void) ownerFinishedWith:(id _Nullable) result error:(NSError* _Nullable) error;
@end

/****************************************************************************************************************
*	DependentPromiseProtocol. Usually you don't need it.  Is needed mostly inside the lib.
*****************************************************************************************************************/
@protocol DependentPromiseProtocol <NSObject>
@required
- (void) ownerReleased; //  owner promise will be deallocated, was not executed
- (void) ownerDoneWithResult:(id) result;
- (void) ownerFailedWithError:(NSError*) error;
@end

//blocks.

//Listener blocks

//For chain

//	block for onEachSuccess method
//  promiseName - name of the promise
//	id - result of promise
//ex : promise.onEachSuccess(^(NSString *promiseName, id result) {...});
typedef void (^ onEachSuccessBlock)(NSString *_Nonnull name, id _Nullable);

//	block for onEachReject method
//  promiseName - name of the promise
//	error - result of promise (in this case error or nil)
//ex : promise.onEachReject(^(NSString *promiseName, NSError) {...});
typedef void (^ OnEachRejectBlock)(NSString *_Nonnull name, NSError *_Nullable error);

//	block for onEachProgress method
//  promiseName - name of the promise
//	progress - progress of promise (0 - 100)
//ex : promise.onEachProgress(^(NSString *promiseName, NSError) {...});
typedef void (^ OnEachProgressBlock)(NSString *_Nonnull name, float progress);

//For particular promise

//	block for onSuccess method
//	value - value of promise
//ex : promise.onSuccess(^(id value) {...});
typedef void (^ OnSuccessBlock)(id _Nullable value);

//	block for onReject method
//	error - value of promise (error or nil in this case)
//ex : promise.onReject(^(NSError *error) {...});
typedef void (^ OnRejectBlock)(NSError *_Nullable);

//	block for onProgress method
//	progress - promise progress
//ex : promise.onProgress(^(NSError *error) {...});
typedef void (^ OnProgressBlock)(float progress);

//condition blocks

//Simple condition block
//Returns YES if condition is true
//NO if not.
//Is used in spIf method as an example of using
typedef  BOOL (^ Condition)(void);

// condition for NSError.
// to check the error type.
// used in spCatch
typedef  BOOL (^ CatchCondition)(NSError *error);

// Condition for the prev. promise result.
// used in spWhere
typedef  BOOL (^ ThenCondition)(id result);

//promise action blocks

// to resolve the promise wiht result
typedef void (^ FulfillBlock)(id _Nonnull result);

// to reject the promise wiht error
typedef void (^ RejectBlock)(NSError *_Nullable error);

// to check if promise is rejected
typedef BOOL (^ IsRejectedBlock)(void);

// to provide current promise progress
typedef void (^ ProgressBlock)(float);

//This is the promise action block itself
typedef void (^ InitBlock)(FulfillBlock _Nonnull, RejectBlock _Nonnull, IsRejectedBlock _Nonnull, ProgressBlock _Nonnull);

//Block for dependent promise in case of owner success
typedef void (^ FutureBlock)(FulfillBlock _Nonnull, RejectBlock _Nonnull, IsRejectedBlock _Nonnull, ProgressBlock _Nonnull, id _Nonnull, id<SomePromiseLastValuesProtocol> _Nonnull);

//Block for dependent promise in case of owner failed
typedef void (^ NoFutureBlock)(FulfillBlock _Nonnull, RejectBlock _Nonnull, IsRejectedBlock _Nonnull, ProgressBlock _Nonnull, NSError *_Nullable error, id<SomePromiseLastValuesProtocol> _Nonnull lastValuesInChain);

//Block for dependent promise in any finish of owner promise
typedef void (^ AlwaysBlock)(id _Nullable, NSError *_Nullable);

//Block for when promise final result part.
typedef void (^ FinalResultBlock)(FulfillBlock _Nonnull, RejectBlock _Nonnull, IsRejectedBlock _Nonnull, ProgressBlock _Nonnull, id _Nullable ownerResult, id _Nullable selfResult, NSError *_Nullable ownerError, NSError *_Nullable selfError, id<SomePromiseLastValuesProtocol> _Nonnull lastValuesInChain);


/****************************************************************************************************************
*	enum PromiseStatus
*	provides promise status
*	ESomePromiseUnknown - unknown (should never be reached)
*	ESomePromiseNonActive - For postponded promises. Promise is ready to start but is not active yet.
*	ESomePromisePending - promise is in active state. Or is waiting for other promise (or waiting for queue/thread be available).
*	ESomePromiseSuccess - Promise has been resolved with non empty result.
*	ESomePromiseRejected - promise has been rejected or finished with error (or nil).
****************************************************************************************************************/
typedef NS_ENUM(NSUInteger, PromiseStatus)
{
   ESomePromiseUnknown,
   ESomePromiseNonActive,
   ESomePromisePending,
   ESomePromiseSuccess,
   ESomePromiseRejected,
};

//Providers classes

/****************************************************************************************************************
* SomeProgressBlockProvider
* in property progressBlock provides progress block inside the promise block in #PROMISE_HELPER methods.
****************************************************************************************************************/
@interface SomeProgressBlockProvider : NSObject

@property (nonatomic, copy)ProgressBlock progressBlock;

@end

/****************************************************************************************************************
* SomeParameterProvider
* in property value provides parameter inside the promise block in #PROMISE_HELPER methods.
****************************************************************************************************************/
@interface SomeParameterProvider : NSObject

@property (nonatomic) id value;
@property (nonatomic, weak) id weakValue;

@end

/****************************************************************************************************************
* SomeIsRejectedBlockProvider
* in property isRejectedBlock provides isRejected block inside the promise block in #PROMISE_HELPER methods.
****************************************************************************************************************/
@interface SomeIsRejectedBlockProvider : NSObject

@property (nonatomic, copy)IsRejectedBlock isRejectedBlock;

@end

/****************************************************************************************************************
* SomeResultProvider
*	provides prev. promise result inside the promise block in #PROMISE_HELPER methods.
*	result - result/nil (prevpromise result)
*	error - NSError/nil (prevpromise result)
*	finished - prev promise has finished.
****************************************************************************************************************/
@interface SomeResultProvider : NSObject

@property (nonatomic)id result;
@property (nonatomic)NSError *error;
@property (nonatomic, readwrite) BOOL finished;

@end

/****************************************************************************************************************
* SomeValuesInChainProvider
*	provides prev. promises results in chain inside the promise block in #PROMISE_HELPER methods.
*	chain - to get lastResultInChain and lastErrorInChain.
****************************************************************************************************************/
@interface SomeValuesInChainProvider : NSObject

@property (nonatomic) id<SomePromiseLastValuesProtocol> chain;

@end

@class SomePromise;
/****************************************************************************************************************
* SomePromiseDelegate Protocol
****************************************************************************************************************/
@protocol SomePromiseDelegate<NSObject>
@optional
/****************************************************************************************************************
* - (void) promise:(SomePromise *_Nonnull) promise gotResult:(id _Nonnull ) result
*	promise has been resolved with result
****************************************************************************************************************/
- (void) promise:(SomePromise *_Nonnull) promise gotResult:(id _Nonnull ) result;

/****************************************************************************************************************
* - (void) promise:(SomePromise *_Nonnull) promise rejectedWithError:(NSError *_Nullable) error;
*	promise has been resolved with error (or nil)
****************************************************************************************************************/
- (void) promise:(SomePromise *_Nonnull) promise rejectedWithError:(NSError *_Nullable) error;

/****************************************************************************************************************
* - (void) promise:(SomePromise *_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
*	promise current state has been changed.
****************************************************************************************************************/
- (void) promise:(SomePromise *_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus;

/****************************************************************************************************************
* - (void) promise:(SomePromise *_Nonnull) promise progress:(float) progress
*	promise current progress has been changed.
****************************************************************************************************************/
- (void) promise:(SomePromise *_Nonnull) promise progress:(float) progress;
@end

/****************************************************************************************************************
* SomePromiseObserver Protocol. Is based on SomePromiseDelegate Protocol. Does not provide new methods.
****************************************************************************************************************/
@protocol SomePromiseObserver<SomePromiseDelegate>
@end

/****************************************************************************************************************
* SomePromiseLastValuesProtocol Protocol. Provides last values in chain
****************************************************************************************************************/
@protocol SomePromiseLastValuesProtocol <NSObject>
- (id _Nullable) lastResultInChain;
-  (NSError *_Nullable) lastErrorInChain;
@end

/****************************************************************************************************************
*	SomeVoid class provides void return in promise.
*	Is a singleton.
****************************************************************************************************************/
@interface SomeVoid : NSObject
+ (_Nonnull instancetype) voidInstance;
@end

/****************************************************************************************************************
* SomePromiseChainPropertyMethods Protocol. Provides methods to create dependant promises
* Can be used by SomePromise or by SomePromiseFuture.
* Note!: provides #PROMISE_HELPER methods marked by #PROMISE_HELPER
* Note!: This protocol uses default implementation in SomePromiseChainMethodsExecutorStrategy
* and provides an example of using SomePromiseUtils to get Protocol Oriented Programming.
****************************************************************************************************************/
@protocol SomePromiseChainPropertyMethods <NSObject>
@optional

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull))then;
*	returns a block:
*	block returns new promise dependent on current.
*	It's FutureBlock will be called only in case of success in current promise
*	In case of error in owner promise it will just return this error too.
*	Note!: All methods in this protocol returns blocks returning promise.
*	On Next descriptions this will be omitted and only description of the block will be rpovided.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull))then;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull))thenOnMain;
*	Is the same as above. But FutureBlock will be executed on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull))thenOnMain;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull))thenOnQueue;
*	The same as above, but FutureBlock will be executed on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull))thenOnQueue;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull))thenOnThread;
*	The same as above, but FutureBlock will be executed in provided thread.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull))thenOnThread;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull))thenWithName;
*	The same as then but provides the name.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull))thenWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull))thenOnMainWithName;
*	The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull))thenOnMainWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull))thenOnQueueWithName;
* the same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull))thenOnQueueWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull))thenOnThreadWithName;
*	the same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull))thenOnThreadWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElse;
*	returns new promise dependent on current
*	If current resolved with value, Future block with this value will be called
*	If current resolved with error, NoFutureBlock with this error will be called
*
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElse;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnMain;
*	The same as above but on man thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, FutureBlock  _Nonnull, NoFutureBlock _Nonnull))thenElseOnMain;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnQueue;
*	The same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnQueue;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnThread;
*	The same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnThread;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseWithName;
*	The same as thenElse but with provided name for the promise
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseWithName;

/****************************************************************************************************************
*
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnMainWithName;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnMainWithName;
*	The same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnQueueWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnThreadWithName
*	The same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, FutureBlock _Nonnull, NoFutureBlock _Nonnull))thenElseOnThreadWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSTimeInterval, FutureBlock _Nonnull))after;
*	Returns new promise depends oncurrent. And it's execution could start only when timeinterval reached
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSTimeInterval, FutureBlock _Nonnull))after;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSTimeInterval, FutureBlock _Nonnull))afterOnMain;
*	The same as above but on the main thread.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSTimeInterval, FutureBlock _Nonnull))afterOnMain;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  dispatch_queue_t _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnQueue;
* 	The same as above but on provided queue.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  dispatch_queue_t _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnQueue;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromiseThread *_Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnThread;
*	The same as above but on provided thread.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromiseThread *_Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnThread;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromise;
*	returns new promise dependent on current.
* 	Also it will start only afte provided promise will be finished.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromise;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnMain
*	The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnMain;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  dispatch_queue_t _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnQueue;
*	the same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  dispatch_queue_t _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnQueue;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromiseThread *_Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnThread;
*	The same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromiseThread *_Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnThread;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromises;
*	returns promise depends on current and could be started only provided promeses be finished.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromises;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnMain
*	the same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnMain;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  dispatch_queue_t _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnQueue;
*	The same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  dispatch_queue_t _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnQueue;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromiseThread *_Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnThread;
*	The same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable,  SomePromiseThread *_Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnThread;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterWithName;
*	tha same as after but with promise name
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnMainWithName;
*	The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnMainWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnQueueWithName;
*	The same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnQueueWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnThreadWithName;
*	The same as above but onprovided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NSTimeInterval, FutureBlock _Nonnull))afterOnThreadWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseWithName
*	The same as after promise but with provided promise name
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseWithName;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnMainWithName;
* The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnMainWithName;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnQueueWithName;
*	the same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnQueueWithName;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnThreadWithName;
* the same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, SomePromise *_Nonnull, FutureBlock _Nonnull))afterPromiseOnThreadWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesWithName
*	The same as afterPromises but with provided name.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnMainWithName;
*	The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnMainWithName;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnQueueWithName;
* the same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnQueueWithName;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnThreadWithName;
*	The same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NSArray<SomePromise*> *_Nonnull, FutureBlock _Nonnull))afterPromisesOnThreadWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThen;
*	returns new promise depends on current.
* Will execute it's block only if current finishes with error.
* Otherwise just return the same value as  current
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThen;

/****************************************************************************************************************
*- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnMain;
*	The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnMain;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnQueue;
*	The same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnQueue;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnThread;
* the same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnThread;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenWithName;
*	the same as ifRejected but with name for new promise.
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenWithName;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnMainWithName;
* The same as above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnMainWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnQueueWithName;
*	The same as above but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnQueueWithName;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnThreadWithName;
*	The same as above but on provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, NoFutureBlock _Nonnull))ifRejectedThenOnThreadWithName;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))when;
*	Returns ne wpromise depends on current and starting it's block at the same time as current.
* 	It has two blcocks. One is it's one independent block (INitBlock)
*	Another is a FinalResultBlock wich will provide the final result of when promise
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))when;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnMain;
*	The same but on main thread
*****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnMain;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnQueue;
*	The same but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, dispatch_queue_t _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnQueue;

/****************************************************************************************************************
*	- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnThread;
*	The same but on provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(Class _Nullable, SomePromiseThread *_Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnThread;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenWithName;
*	The same as when but with provided when promise name
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenWithName;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnMainWithName;
*	The same aws above but on main thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnMainWithName;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnQueueWithName;
*	The same as abovebut with provided queue
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, dispatch_queue_t _Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnQueueWithName;

/****************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnThreadWithName;
* The same as above but with provided thread
****************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSString *_Nullable, Class _Nullable, SomePromiseThread *_Nullable, InitBlock _Nonnull, FinalResultBlock _Nonnull))whenOnThreadWithName;

/****************************************************************************************************************
* - (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(AlwaysBlock _Nonnull))always;
*	always does not provide new promise.
*	it returns the same promise.
*	It's AlwaysBlock will be called in any result of current promise.
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(AlwaysBlock _Nonnull))always;

/****************************************************************************************************************
* - (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(AlwaysBlock _Nonnull))alwaysOnMain;
*	The same as above but on man thread
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(AlwaysBlock _Nonnull))alwaysOnMain;

/****************************************************************************************************************
* - (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, AlwaysBlock _Nonnull))alwaysOnQueue;
*	The same as above but on provided queue
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, AlwaysBlock _Nonnull))alwaysOnQueue;

/****************************************************************************************************************
* - (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, AlwaysBlock _Nonnull))alwaysOnThread;
* The same as above but on provided thread
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, AlwaysBlock _Nonnull))alwaysOnThread;

/****************************************************************************************************************
*#PROMISE_HELPER methods !!!!!!!!!!!
****************************************************************************************************************/

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nonnull creationBlock, ...))spNext
* Returns block returning new promise depends on current.
*	This promise will be executed in both cases. Owner failed or owner succeded.
*	parameters:
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
*
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nonnull creationBlock, ...))spNext; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nonnull creationBlock, ...))spThen
* Returns block returning new promise depends on current.
*	This promise will be executed in case of owner succeded.
*	parameters:
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
*
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nonnull creationBlock, ...))spThen; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nonnull creationBlock, ...))spElse
* Returns block returning new promise depends on current.
*	This promise will be executed in case of owner rejected/failed.
*	parameters:
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
*
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(id _Nonnull creationBlock, ...))spElse; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(Condition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spIf
* Returns block returning new promise depends on current.
*	This promise will be executed in both cases. Owner failed or owner succeded but also condition should succeded.
*	parameters:
*	condition: a condition block ^(){return (BOOL)(condition);}
				is checked before promise start.
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
*	ex:
//  	spTry(^{
//		//Something
//	  }).spIf(CONDITION(3 == 4), ^
//	  {
//		NSLog(@"NEVER be here");
//	  }).onReject(^(NSError *error){
//	      NSLog(@"spIf rejected %@", error);
//	  })
*
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(Condition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spIf; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(CatchCondition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spCatch;
* Returns block returning new promise depends on current.
*	This promise will be executed in cases of Owner failed/rejected but also condition should succeded.
*	parameters:
*	condition: a condition block CatchCondition - ^(NSError *error){return (BOOL)(condition);}
				is checked before promise start.
				So you can check the error type here.
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
*	ex:
//    spTry(^{
//		//Something
//	  }).spIf(CONDITION(3 == 4), ^ //here will reject with error code 6 (condition failed)
//	  {
//		NSLog(@"NEVER be here");
//	  }).onReject(^(NSError *error){
//	      NSLog(@"spIf rejected %@", error);
//	  }).spCatch(ERROR_CONDITION(error.code == 6), ^ //6 is a code for condition failed
//	  {
//		  //do nothing. Should have Void in success
//	  }).onSuccess(^(id result){
//	      NSLog(@"cp catch!! %@", result); //will show void
//	  })
*
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(CatchCondition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spCatch; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(ThenCondition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spWhere
* Returns block returning new promise depends on current.
*	This promise will be executed in cases of Owner resolved with result but also condition should succeded.
*	parameters:
*	condition: a condition block ResultCondition - ^(id result){return (BOOL)(condition);}
				is checked before promise start.
				So you can check the result of owner here.
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
*	ex:
//    spTry(^{
//		return 3;
//	  }).spWhere(RESULT_CONDITION([result integerValue] == 3), ^
!!	  	{
!!		  some long action wich takes result == 5
!!	      return 5;
!!	  	})
*
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(ThenCondition _Nullable conditionBlock, id _Nonnull creationBlock, ...))spWhere; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(NSTimeInterval timeInterval, id _Nonnull creationBlock, ...))spAfterTime
* Returns block returning new promise depends on current.
*	This promise will be executed in cases of Owner resolved with result but after time interval.
*	parameters:
*	 timeInterval: interval to start the promise
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(NSTimeInterval timeInterval, id _Nonnull creationBlock, ...))spAfterTime; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(NSArray<SomePromise*> *_Nullable promises, id _Nonnull creationBlock, ...))spAfter
* Returns block returning new promise depends on current.
*	This promise will be executed in cases of Owner resolved with result but after promises finished.
*	parameters:
*	 promises: promises to be waiting for.
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	promises - array of promises to wait for resolve
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(NSArray<SomePromise*> *_Nullable promises, id _Nonnull creationBlock, ...))spAfter; //#PROMISE_HELPER

/****************************************************************************************************************
*	- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(FinalResultBlock _Nonnull finalResultBlock, id _Nonnull creationBlock, ...))spWhen;
* Returns block returning new promise depends on current.
*	This promise will be executed in the same time as current
*	parameters:
*	 timeInterval: interval to start the promise
*	 creationBlock: is an action block for the promise.
*	 ...: promise parameters in any order. Provide values after the promise action block.
*	Possible parameters and their values:
*
*	promises - array of promises to wait for resolve
*
*	Class - class for the value
*
*	NSString* name - name of the promise
*
*	SomePromiseThread* - thread for the promise
*
*	SomePromiseSettingsPromiseWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise.
*
*	SomePromiseSettingsPromiseDelegateWorker* - See SomePromiseTypes.h for description. Provides thread or queue for promise delegate.
*
*	SomePromiseDelegateWrapper* - See SomePromiseTypes.h for description. Provides a delegate.
*
*	SomePromiseSettingsObserverWrapper* - See SomePromiseTypes.h for description. Provides observers.
*
*	SomeProgressBlockProvider* - See SomePromiseTypes.h for description. Provides progress block for promise. Call this block inside promise
*	action body to provide action progress for handlers (listeners, delegate, observers).
*
*	SomeIsRejectedBlockProvider* - See SomePromiseTypes.h for description. Provides isRejected block for promise.  Call this block inside promise
*	action body to check if promise is already rejected from outside.
*
*	SomeValuesInChainProvider* - provides last result/error in chain
*
*	SomeResultProvider* - provides owner result.
****************************************************************************************************************/
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull (^ __nonnull)(FinalResultBlock _Nonnull finalResultBlock, id _Nonnull creationBlock, ...))spWhen; //#PROMISE_HELPER

@end


/****************************************************************************************************************
* SomePromiseChainMethods Protocol. Provides methods to create dependant promises
* Can be used by SomePromise or by SomePromiseFuture.
* Methods are the same as for SomePromiseChainPropertyMethods
* But returns new (or same) promise directly, not by block.
* Anyway parameter description are the same, so descriptions are ommited.
* Note!: does not provide #PROMISE_HELPER methods
* Note!: This protocol uses default implementation in SomePromiseChainMethodsExecutorStrategy
* and provides an example of using SomePromiseUtils to get Protocol Oriented Programming.
****************************************************************************************************************/
@protocol SomePromiseChainMethods <NSObject>
@optional
- (SomePromise *_Nonnull) thenExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenOnQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenOnThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenOnMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenExecute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nonnull) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nonnull) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenOnQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenOnThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body elseExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenOnMainExecute:(FutureBlock _Nonnull) body elseOnMainExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) thenWithName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull) body elseOnMainExecute:(NoFutureBlock _Nullable) elseBody class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) after:(NSTimeInterval) interval withName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromise:(SomePromise *_Nonnull) promise withName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) afterPromises:(NSArray<SomePromise*> *_Nonnull) promises withName:(NSString *_Nullable) name onMainExecute:(FutureBlock _Nonnull) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectExecute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectOnQueue:(dispatch_queue_t _Nullable) queue execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectOnThread:(SomePromiseThread *_Nullable) thread execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectOnMainExecute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) onRejectWithName:(NSString *_Nullable) name onMainExecute:(NoFutureBlock _Nullable) body class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenExecute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenOnQueue:(dispatch_queue_t _Nullable) queue execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenOnThread:(SomePromiseThread *_Nullable) thread execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name onQueue:(dispatch_queue_t _Nullable) queue execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name onThread:(SomePromiseThread *_Nullable) thread execute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenOnMainExecute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise *_Nonnull) whenWithName:(NSString *_Nullable) name onMainExecute:(InitBlock _Nonnull) body resultBlock:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysExecute:(AlwaysBlock _Nonnull) body;
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysOnQueue:(dispatch_queue_t _Nullable) queue execute:(AlwaysBlock _Nonnull) body;
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysOnThread:(SomePromiseThread *_Nullable) thread execute:(AlwaysBlock _Nonnull) body;
- (id<SomePromiseChainMethodsExecutorStrategyUser>_Nonnull) alwaysOnMainExecute:(AlwaysBlock _Nonnull) body;

@end

//SomePromiseSettings

/******************************************************************************************
* class SomePromiseSettingsQueueOrThread
*	Provides wrapper for queue or thread (not both in one time).
*
*	Is abstract base class.
*******************************************************************************************/
@interface SomePromiseSettingsQueueOrThread: NSObject

@property (nonatomic, nullable) SomePromiseThread *thread;
@property (nonatomic, nullable) dispatch_queue_t queue;

@end

/******************************************************************************************
* class SomePromiseSettingsPromiseWorker
*	Provides wrapper for queue or thread (not both in one time).
*
*	Is used in promise settings.
*	Determine what queue/thread promise should use for it's action.
*
*******************************************************************************************/
@interface SomePromiseSettingsPromiseWorker: SomePromiseSettingsQueueOrThread
@end

/******************************************************************************************
* class SomePromiseSettingsPromiseDelegateWorker
*	Provides wrapper for queue or thread (not both in one time).
*
*	Is used in promise settings.
*	Determine what queue/thread promise delegate should use for it's action.
*
*******************************************************************************************/
@interface SomePromiseSettingsPromiseDelegateWorker: SomePromiseSettingsQueueOrThread
@end

@class ObserverAsyncWayWrapper;

/******************************************************************************************
* class SomePromiseSettingsObserverWrapper
*	Provides wrapper for promise observers.
*
*	Is used in promise settings.
*
*******************************************************************************************/
@interface SomePromiseSettingsObserverWrapper: NSObject

@property (nonatomic, nonnull) NSMapTable<id<SomePromiseObserver>, ObserverAsyncWayWrapper*> *observers;

- (void) addObserver:(id<SomePromiseObserver>)observer onQueue:(dispatch_queue_t)queue;
- (void) addObserver:(id<SomePromiseObserver>)observer onThread:(SomePromiseThread*)thread;
- (void) addObservers:(NSArray<id<SomePromiseObserver> >*)observers onQueue:(dispatch_queue_t)queue;
- (void) addObservers:(NSArray<id<SomePromiseObserver> >*)observers onThread:(SomePromiseThread*)thread;
- (void) removeObserver:(id<SomePromiseObserver>)observer;
- (void) clear;

@end

/******************************************************************************************
* class SomePromiseSettingsOnSuccessBlocksWrapper
*	Provides wrapper for promise onSuccess listeners
*
*	Is used in promise settings.
*
*******************************************************************************************/
@interface SomePromiseSettingsOnSuccessBlocksWrapper: NSObject
@property (nonatomic, nonnull) NSMutableArray<OnSuccessBlock> *onSuccessBlocks;
@end

/******************************************************************************************
* class SomePromiseSettingsOnRejectBlocksWrapper
*	Provides wrapper for promise onReject listeners
*
*	Is used in promise settings.
*
*******************************************************************************************/
@interface SomePromiseSettingsOnRejectBlocksWrapper: NSObject
@property (nonatomic, nonnull) NSMutableArray<OnRejectBlock> *onRejectBlocks;
@end


/******************************************************************************************
* class SomePromiseSettingsOnProgressBlocksWrapper
*	Provides wrapper for promise onProgress listeners
*
*	Is used in promise settings.
*
*******************************************************************************************/
@interface SomePromiseSettingsOnProgressBlocksWrapper: NSObject
@property (nonatomic, nonnull) NSMutableArray<OnProgressBlock> *onProgressBlocks;
@end

/******************************************************************************************
* class SomePromiseSettingsResolvers
*	Provides wrapper for promise action block
*
*	Is used in promise settings.
*
*******************************************************************************************/
@interface SomePromiseSettingsResolvers: NSObject
@property (nonatomic, copy, nullable) InitBlock initBlock;
@property (nonatomic, copy, nullable) FutureBlock futureBlock;
@property (nonatomic, copy, nullable) NoFutureBlock noFutureBlock;
@property (nonatomic, copy, nullable) FinalResultBlock finalResultBlock;
@end

/******************************************************************************************
* class SomePromiseDelegateWrapper
*	Provides wrapper for promise delegate
*
*	Is used in promise settings.
*
*******************************************************************************************/
@interface SomePromiseDelegateWrapper: NSObject

@property (nonatomic, weak, nullable) id<SomePromiseDelegate> delegate;

@end

/******************************************************************************************
* class SomePromiseSettings
* Can be used to recreate a promise.
*	is not mutable.
*******************************************************************************************/
@class SomePromiseMutableSettings;
@interface SomePromiseSettings: NSObject

@property (nonatomic, copy, readonly, nonnull) NSString *name;
@property (nonatomic, readonly) PromiseStatus status;
@property (nonatomic, readonly, nullable) Class futureClass;
@property (nonatomic, readonly, nonnull) SomePromiseSettingsResolvers *resolvers;
@property (nonatomic, readonly, nullable) SomePromiseSettingsObserverWrapper *observers;
@property (nonatomic, readonly, nonnull) SomePromiseSettingsPromiseWorker *worker;
@property (nonatomic, readonly, nullable) SomePromiseDelegateWrapper *delegate;
@property (nonatomic, readonly, nullable) SomePromiseSettingsPromiseDelegateWorker *delegateWorker;
@property (nonatomic, readonly, nullable) SomePromiseSettingsOnSuccessBlocksWrapper *onSuccessBlocks;
@property (nonatomic, readonly, nullable) SomePromiseSettingsOnRejectBlocksWrapper *onRejectBlocks;
@property (nonatomic, readonly, nullable) SomePromiseSettingsOnProgressBlocksWrapper *onProgressBlocks;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, readonly, nullable) NSError *ownerError;
@property (nonatomic, readonly, nullable) id value;
@property (nonatomic, readonly, nullable) id ownerValue;
@property (nonatomic, readonly)BOOL resolved;
@property (nonatomic, readonly)BOOL forcedRejected;
@property (nonatomic, readonly, nullable)id chain;
@property (nonatomic) NSMutableArray<SomeParameterProvider*> * parameters;

@property (nonatomic, readwrite) SomeProgressBlockProvider *progressBlockProvider;
@property (nonatomic, readwrite) SomeIsRejectedBlockProvider *isRejectedBlockProvider;

- (BOOL) consistent;
- (SomePromiseSettings*) freshCopy;
- (SomePromiseMutableSettings*) mutableCopy;

@end

/******************************************************************************************
* class SomePromiseMutableSettings
* Can be used to recreate a promise.
*	is mutable.
*******************************************************************************************/
@interface SomePromiseMutableSettings: SomePromiseSettings
@property (nonatomic, copy, nonnull) NSString *name;
@property (nonatomic) PromiseStatus status;
@property (nonatomic, nullable) Class futureClass;
@property (nonatomic, nonnull) SomePromiseSettingsResolvers *resolvers;
@property (nonatomic, nullable) SomePromiseSettingsObserverWrapper *observers;
@property (nonatomic, nonnull) SomePromiseSettingsPromiseWorker *worker;
@property (nonatomic, nullable) SomePromiseDelegateWrapper *delegate;
@property (nonatomic, nullable) SomePromiseSettingsPromiseDelegateWorker *delegateWorker;
@property (nonatomic, nullable) SomePromiseSettingsOnSuccessBlocksWrapper *onSuccessBlocks;
@property (nonatomic, nullable) SomePromiseSettingsOnRejectBlocksWrapper *onRejectBlocks;
@property (nonatomic, nullable) SomePromiseSettingsOnProgressBlocksWrapper *onProgressBlocks;
@property (nonatomic, nullable) NSError *error;
@property (nonatomic, nullable) NSError *ownerError;
@property (nonatomic, nullable) id value;
@property (nonatomic, nullable) id ownerValue;
@property (nonatomic)BOOL resolved;
@property (nonatomic)BOOL forcedRejected;
@property (nonatomic, nullable)id chain;
@property (nonatomic) NSMutableArray<SomeParameterProvider*> * parameters;

- (SomePromiseSettings*) copy;

@end


//weak key. strong value.
@interface SPMapTable<__covariant K, __covariant V>: NSObject

+ (instancetype) new;
- (V) objectForKey:(K)key;
- (void) setObject:(V)object forKey:(K)key;
- (NSUInteger) count;
- (NSEnumerator*) keyEnumerator;
- (void) removeObjectForKey:(K)key;
- (void) removeAllObjects;

@end

/*
	SPPair is a simple class for providing two values.
	Note!: is not thread safe.
*/
@interface SPPair<__covariant Left, __covariant Right>: NSObject

+ (instancetype) pairWithLeft:(Left _Nullable)left right:(Right _Nullable)right;

@property (nonatomic, strong, nullable) Left left;
@property (nonatomic, strong, nullable) Right right;

@end

/*
 	SomeTupleCommand enum
 	Determine actions to d owith tuple.
 		SomeTupleCount	return number of elements
		SomeTupleValue 	return value (by index)
		SomeTupleType 	return object type by index
		SomeTupleGet	return NSArray of all elements in tuple.
 		SomeTupleGetNames	return NSArray of all names tule has.
*/
typedef NS_ENUM(NSUInteger, SomeTupleCommand)
{
	SomeTupleCount = 0,
	SomeTupleValue = 1,
	SomeTupleType = 2,
	SomeTupleName = 3,
	SomeTupleGet = 4,
	SomeTupleGetNames = 5,
};

#define sp_named(name, value) "Should be called with @" @"".length ? [SPPair pairWithLeft:[NSString stringWithUTF8String:#name] right:value] : nil

typedef id (^tupleReturnBlock)(id);
//typedef id (^ SomeTupleValueF)(id index);
//typedef NSInteger (^ SomeTupleCountF)(void);
//typedef Class (^ SomeTupleTypeF)(id index);
//typedef NSArray* (^ SomeTupleGetF)(void);

typedef tupleReturnBlock (^ SomeTuple)(SomeTupleCommand command);


//create a tuple.
//May be used with SPTuple class.
//params.
// number - Number of elements
// ... - elements
SomeTuple createTuple(NSInteger number, ...);
//SomeTupe is actually a block already located in heap.

//SPTuple class - represents tuple
//
@interface SPTuple : NSObject

//change/get tuple.
//tuple can have named parameters. It is SPPair with left - name, right - value.
@property (nonnull ,nonatomic, copy) SomeTuple tuple;

//create SPTuple for tuple.
+ (SPTuple*) new:(SomeTuple)tuple;
//count of elements in tuple.
+ (NSInteger) countForTuple:(SomeTuple)tuple;
//element at index in tuple.
+ (id) valueForTuple:(SomeTuple)tuple at:(NSUInteger) index;
//type of element at index in tuple.
+ (Class) typeForTuple:(SomeTuple)tuple at:(NSUInteger) index;
//element with name in tuple.
+ (id) valueForTuple:(SomeTuple) tuple withName:(NSString*)name;
//name for element in tuple at index.
+ (NSString *_Nullable) nameForTuple:(SomeTuple)tuple at:(NSUInteger) number;
// All names in tuple.
+ (NSArray<NSString*>*) namesForTuple:(SomeTuple) tuple;
// Array of all values of tuple
+ (NSArray*) getValuesForTuple:(SomeTuple) tuple;

//The same for current tuple.
- (NSInteger) count;
- (id) valueAt:(NSUInteger) index;
- (Class) typeAt:(NSUInteger) index;
- (id) valueByName:(NSString*) name;
- (NSString *_Nullable) nameAt:(NSUInteger) index;
- (NSArray<NSString*>*) names;
- (NSArray*) getValues;

@end

/*****************************************************************
* SPArray is a mutable array with possibility to store elements strongly or weakly.
* It can contain nils. It provides shrink method to remove nils in place.
* Shrinking can be done automatically.
* Also it is possible to get copy without nils.
* It is a threadsafe object.
*
*!NOTE: For most content modification methods it has mutating and not mutating variants
*!Using not mutating you will get a copy of SPArray each time.
*!This implementation is not Lazy and does not support a self implemented CoW (only what objective-c has).
*!So it might have a bad impact to perfomance, it does allocation on each call of nonmutating method.
*!Note: Mutating methods have a simple names, like "add"
*!Not mutating would have names with "ed" suffix such as "added".
*!Also it supports returning block variants (to make it possible to use them in chain without many [[[[[).
*!For theese methods mutating names are simple "add(parameters)" and return self.
*!Not mutating method has "ing" suffix like "adding(parameters)"
******************************************************************/

//Block for reducing of array.
typedef id (^ReduceBlock)(id lastResult, NSUInteger startindex);

//
// SPArrayElementWrapper is an abstract class.
// It is used as a return value of a SPArray.
// Is needed to allow nil as a value
// To support fast enumerations and so on.
// Is not used as a value to be stored in SPArray.
// If you have a ref to SPArrayElementWrapper and you want to store it in SPArray
// Use it's value instead.
// If add you SPArrayElementWrapper SPArray will unwrap it.
//

@interface SPArrayElementWrapper<__covariant T> : NSObject
- (T _Nullable) value;
- (BOOL) weakly;

@end

//Use @sp_weakly() to store elements weakly in SPArray on array creaition. Or just addWeakly methods
@interface __SPArrayElementWrapperWeak : SPArrayElementWrapper
- (instancetype) initWithValue:(id)value;

@property (nonatomic, readonly, weak) id value;
@end

@interface SPArray<__covariant T> : NSObject <NSFastEnumeration, NSCopying>

typedef NSComparisonResult (^ SPArrayCompareBlock)(SPArrayElementWrapper<T> *_Nonnull first, SPArrayElementWrapper<T> *_Nonnull second);
typedef BOOL (^ SPArrayFilterBlock)(T object);
typedef BOOL (^ SPArrayFilterWrapperBlock)(SPArrayElementWrapper *wrapper);
typedef id (^ SPArrayMapBlock)(T object);
typedef void (^ SPArrayForEachBlock)(T _Nullable object, NSUInteger index, BOOL *stop);

//create empty array
+ (instancetype) new;

//create empty array
+ (instancetype) array;
//create empty array with capacity
+ (instancetype) arrayWithCapacity:(NSUInteger)capacity;
//create SPArray from NSArray. All elements will be stored strongly.
+ (instancetype) fromArray:(NSArray*)array;
//create SPArray from NSArray. All elements will be stored weakly.
+ (instancetype) fromArrayWeakly:(NSArray*)array;
//create SPArray from another SPArray. Just copy,
+ (instancetype) arrayWithSPArray:(SPArray*)array;

- (instancetype) init;
- (instancetype) initWithCapacity:(NSUInteger)capacity;
- (instancetype) initWithArray:(NSArray*)array;
- (instancetype) initWithArrayWeakly:(NSArray*)array;
- (instancetype) initWithSPArray:(SPArray*)array;

//Setting this parameter to YES will not allow to store nils in array.
//All nils will be removed.
//Weak elements will be also removed just after been removed from memory. No nils will be kept.
//By default is NO. It keeps nils by default.
@property (nonatomic) BOOL autoshrink;
//is array sorted or not. By default is not even if you provide sorted values.
//Sortes will be set to YES after you make sorting.
//Will be back to NO after any content change, even if this change is made in right sorted order.
@property (nonatomic, readonly) BOOL sorted;
//Number of elements in array.
@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic, readonly) BOOL changable;

//enumerations & subscript
- (SPArrayElementWrapper<T>*) objectAtIndexedSubscript:(NSUInteger)idx;
- (void) setObject:(T _Nullable)obj atIndexedSubscript:(NSUInteger)idx;

//Fast Enumeration: for (SPArrayElementWrapper *element in SPArrayInstance)
//Fast enumeration blocks array for changes while enumeration is in progress.
//It means all threads trying to make changes in SPArray will wait fast enumeration be finished
//before it(thread) can mutate the SPArray.
//Other fast enumeration in another thread is available at the same time.
//Mutation will be allowed after all fast enumerations finished.

//! NOTE: it does not have to have anyting in header file to support fust enumeration.
//! just keep in mind it is supported.

//Other enumeration variants:

//enumerateObjectsUsingBlock
//enumerating in block you get not wrapper but an element itself
//possible nil.
//! NOTE: enumerateObjectsUsingBlock does not lock Array for changes it enumerates in copy of array
//! Use fast enumeration if you need SPArray be locked during enumeration
- (void)enumerateObjectsUsingBlock:(void (^)(T _Nullable obj, NSUInteger idx, BOOL *stop))block;
- (SPArray *_Nonnull(^ __nonnull)(void (^block)(T _Nullable obj, NSUInteger idx, BOOL *stop)))enumerateObjectsUsingBlock;

//The same but in reverse order.
- (void)reverslyEnumerateObjectsUsingBlock:(void (^)(T _Nullable obj, NSUInteger idx, BOOL *stop))block;
- (SPArray *_Nonnull(^ __nonnull)(void (^block)(T _Nullable obj, NSUInteger idx, BOOL *stop)))reverslyEnumerateObjectsUsingBlock;

//objectEnumerator
//This is "an old" way of making enumeration.
//You get an enumeration object (instance of NSEnumerator) and call it's nextobject method while it does not return nil to you.
//enumeration by enumerator object returns you wrapper with possible value field = nil.
//Due to nil has a special meaning in case of using enumerator class instance, the raw value can't be returned (as it culd be nil).
//Thus nextObject method is used to return you an instance of SPArrayElementWrapper with value field equals to value stored in SPArray.
//This (value) field could be nil.
//! NOTE: enumerator does not lock Array for changes; Enumerator takes array copy.
//! Use fast enumeration if you need SPArray be locked during enumeration
- (NSEnumerator*)objectEnumerator;

//The same but in reverse order.
- (NSEnumerator*)reversedObjectEnumerator;

//forEach:
//forEach as above  variants of enumerations is also used for enumerating throug the SPArray without mutatitng it.
//It looks pretty common with enumerateObjectsUsingBlock and has the same logic and usecase.
//The diffrence with previous variant is that it blocks other forEach enumerations.
//It locks not only mutation but any kind of access to the internal array of SPArray. And changing any propertes of SPArray
//could be presented only after forEach completly done.
//It also blocks other enumeration variants if they were not started before foreach has been called.
//Otherwise there could be a race condition between enumerations.
//Depends on other variants using internal array copy has made a copy already (before foreach has started) or not.
//At the moment of foreach working internal array is blocked and can not be coped.
//This (race condion case) is also true for fast enumeration due to it uses syncronized access for some
//properties of the internal array such as count, in fact it means calling foreach simultaneously(while fast enumeration is active)
//with fast enumeration can presume fast enumeration be frozen at the middle (at any possile index position), and could be only continued after forech is done.
//So be carefull with using a forEach method.
//This could be useful if you have a situation
//When you do enumeration from diffrent threads but actions for each element should not be done
//at the same time. But this could (probably should) be handled in your own code logic.
//! NOTE: It enumerates in place (does not do a copy of internal array)
//! NOTE: Enumeration is presented inside SPArray syncronization queue.
//! Not in queue you have called the forech method.
//! But it will be done syncroniously, so your thread will be locked for enumeration cycling time.
//! NOTE: Usually it is better to avoid using forEach. Use fast enumeration, enumerateObjectsUsingBlock or enumerator object instead.
- (void)forEach:(SPArrayForEachBlock) block;
- (SPArray *_Nonnull(^ __nonnull)(SPArrayForEachBlock block))forEach;

//mutating methods

//remove all nils (just once).
- (void) shrink;
//add an object strongly.
- (void) add:(T)object;
//add an object weakly.
- (void) addWeakly:(T)object;
//add element weakly or strongly at the beginning.
- (void) pushForward:(T)object weakly:(BOOL)weakly;
//insert object at index weakly or strongly.
- (void) insertAtIndex:(NSUInteger) index object:(T)object weakly:(BOOL)weakly;
//remove object.
- (void) remove:(T)object;
//remove object at index.
- (void) removeAtIndex:(NSUInteger)index;
//add SPArray from NSArray to the end of current array.
- (void) appendArray:(NSArray*)array;
//add SPArray from NSArray starting at index of current array.
- (void) insertArray:(NSArray*)array atIndex:(NSUInteger)index;
//add SPArray from NSArray starting at the beginning of current array.
- (void) pushArrayForward:(NSArray*) array;
//add SPArray at the end
- (void) appendSPArray:(SPArray*)array;
//add SPArray at the index
- (void) insertSPArray:(SPArray*)array atIndex:(NSUInteger)index;
//add SPArray at the beginning
- (void) pushSPArrayForward:(SPArray*) array;
//sort array using block providing comparition rule for elements.
- (void) sortWithBlock:(SPArrayCompareBlock)block;
//filter array (remove elements by block condition)
- (void) filter:(SPArrayFilterBlock)block;
//filter array (remove wrapper by block condition)
- (void) filterWrappers:(SPArrayFilterWrapperBlock)block;
//change each element using block.
- (void) map:(SPArrayMapBlock)block;
//change array order to backward one.
- (void) reverse;
//change two elements position to each other.
- (void) swap:(NSUInteger)element1Index with:(NSUInteger)element2Index;
//If SPArray contains sub SPArrrays as parameters, just open them and add it's elements directly. On the same places.
- (void) flat;
//mix array elements in random order
- (void) shuffle;

//Mutating blocks. Returns self to be used in chain.
- (SPArray *_Nullable(^ __nonnull)(T object))add;
- (SPArray *_Nullable(^ __nonnull)(T object))addWeakly;
- (SPArray *_Nullable(^ __nonnull)(T object, BOOL weakly))pushForward;
- (SPArray *_Nullable(^ __nonnull)(T object, NSUInteger index, BOOL weakly))insertAtIndex;
- (SPArray *_Nullable(^ __nonnull)(T object))remove;
- (SPArray *_Nullable(^ __nonnull)(NSUInteger index))removeAtIndex;
- (SPArray *_Nullable(^ __nonnull)(NSArray *array))appendArray;
- (SPArray *_Nullable(^ __nonnull)(NSArray *array, NSUInteger index))insertArrayAtIndex;
- (SPArray *_Nullable(^ __nonnull)(NSArray *array))pushArrayForward;
- (SPArray *_Nullable(^ __nonnull)(SPArray *array))appendSPArray;
- (SPArray *_Nullable(^ __nonnull)(SPArray *array, NSUInteger index))insertSPArrayAtIndex;
- (SPArray *_Nullable(^ __nonnull)(SPArray *array))pushSPArrayForward;
- (SPArray *_Nullable(^ __nonnull)(SPArrayCompareBlock block))sort;
- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterBlock block))filter;
- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterWrapperBlock block))filterWrappers;
- (SPArray *_Nullable(^ __nonnull)(SPArrayMapBlock block))map;
- (SPArray *_Nullable(^ __nonnull)(void))makeFlat;
- (SPArray *_Nullable(^ __nonnull)(void))doShuffle;
- (SPArray *_Nullable(^ __nonnull)(void))doRevers;
- (SPArray *_Nullable(^ __nonnull)(NSUInteger first, NSUInteger second))swap;

//not mutating methods // the same as above but return results in new array
- (SPArray*) shrinked;
- (SPArray*) reversed;
- (SPArray*) swapped:(NSUInteger)element1Index with:(NSUInteger)element2Index;
- (SPArray*) mapped:(SPArrayMapBlock)block;
- (id) reduceResult:(id) result block:(ReduceBlock)block;
- (SPArray*) filtered:(SPArrayFilterBlock)block;
- (SPArray*) filteredWrappers:(SPArrayFilterWrapperBlock)block;
- (SPArray*) sortedWithBlock:(SPArrayCompareBlock)block;
- (T _Nullable) getByIndex:(NSUInteger)index;
- (BOOL) has:(T)object;
- (BOOL) isEmpty;
- (NSDictionary<NSNumber*, SPArrayElementWrapper<T>*>*) enumerated;
- (T _Nullable) randomElement;
- (NSArray*) toArray;
- (NSArray*) toArrayWithWrappers;
- (T _Nullable) last;
- (T _Nullable) first;
- (SPArray*) insertedArray:(NSArray*)array atIndex:(NSUInteger)index;
- (SPArray*) insertedSPArray:(SPArray*)array atIndex:(NSUInteger)index;
- (SPArray*) insertedAtIndex:(NSUInteger)index object:(T) object weakly:(BOOL)weakly;
- (SPArray*) added:(T)object;
- (SPArray*) addedWeakly:(T)object;
- (SPArray*) pushedForward:(T)object weakly:(BOOL)weakly;
- (SPArray*) removed:(T)object;
- (SPArray*) removedAtIndex:(NSUInteger)index;
- (SPArray*) appendedArray:(NSArray*)array;
- (SPArray*) appendedSPArray:(SPArray*)array;
- (SPArray*) pushedArrayForward:(NSArray*) array;
- (SPArray*) pushedSPArrayForward:(SPArray*) array;
- (SPArray*) range:(NSRange)range;
- (SPArray*) copy;
- (SPArray*) flatted;
- (SPArray*) shuffled;
- (Class) typeForIndex:(NSUInteger)index;
- (BOOL) isElementWeaklyStoredAtIndex:(NSUInteger)index;

- (SPArray *_Nullable(^ __nonnull)(void))shrinking;
- (SPArray *_Nullable(^ __nonnull)(void))reversing;
- (SPArray *_Nullable(^ __nonnull)(NSUInteger first, NSUInteger second))swapping;
- (SPArray *_Nullable(^ __nonnull)(SPArrayMapBlock block))mapping;
- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterBlock block))filtering;
- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterWrapperBlock block))filteringWrappers;
- (SPArray *_Nullable(^ __nonnull)(SPArrayCompareBlock block))sorting;
- (SPArray *_Nullable(^ __nonnull)(T object))removing;
- (SPArray *_Nullable(^ __nonnull)(NSUInteger index))removingAtIndex;
- (SPArray *_Nullable(^ __nonnull)(T object))adding;
- (SPArray *_Nullable(^ __nonnull)(T object))addingWeakly;
- (SPArray *_Nullable(^ __nonnull)(T object, BOOL weakly))pushingForward;
- (SPArray *_Nullable(^ __nonnull)(NSArray *array, NSUInteger index))insertingArrayAtIndex;
- (SPArray *_Nullable(^ __nonnull)(NSArray *array))appendingArray;
- (SPArray *_Nullable(^ __nonnull)(SPArray *array))appendingSPArray;
- (SPArray *_Nullable(^ __nonnull)(SPArray *array, NSUInteger index))insertingSPArrayAtIndex;
- (SPArray *_Nullable(^ __nonnull)(NSArray *array))pushingArrayForward;
- (SPArray *_Nullable(^ __nonnull)(SPArray *array))pushingSPArrayForward;
- (SPArray *_Nullable(^ __nonnull)(T object, NSUInteger index, BOOL weakly))insertingAtIndex;
- (SPArray *_Nullable(^ __nonnull)(void))flatting;
- (SPArray *_Nullable(^ __nonnull)(void))shuffling;

@end

#endif /* SomePromiseTypes_h */
