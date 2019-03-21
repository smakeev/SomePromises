//
//  SomePromise.h
//  SomePromises
//
//  Created by Sergey Makeev on 08/01/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

/*************************************************
* SomePromise.h is the main file of a library.
*	To use the whole objective-c part of the library you need to import only this one file.
*	It provides SomePromise interface.
*
**************************************************/

#import <Foundation/Foundation.h>
#import "SomePromiseFuture.h"
#import "SomePromiseThread.h"
#import "SomePromiseInternals.h"
#import "SomePromiseTypes.h"
#import "SomePromiseChainMethodsExecutorStrategy.h"
#import "SomePromiseUtils.h"
#import "SomePromiseExtend.h"
#import "SomePromiseEvents.h"
#import "SomePromiseSignal.h"
#import "SomePromiseLocContainer.h"
#import "SomePromiseDataStream.h"
#import "SomePromiseObject.h"
#import "SomePromiseMayBe.h"
#import "SomePromiseFunctor.h"
#import "SomePromiseGenerator.h"
#import "SPAsyncAwait.h"
#import "SPActor.h"

//=======================================================================================================================
//*	defines
//=======================================================================================================================

/*************************************************
* Void
*
*	To make it possible to return void from the promise block
*	SomeVoid type has been created.
*
**************************************************/
#define Void [SomeVoid voidInstance]
#define VoidReturn return [SomeVoid voidInstance];

/*************************************************
* CONDITION
*
*	Some of promise methods could use conditions
*	This is a block returnong a bool value.
*	To make it easer you may use these defines instead of creating blocks.
*
**************************************************/
#define CONDITION(condition) ^(){return (BOOL)(condition);}
#define ERROR_CONDITION(condition) ^(NSError *error){return (BOOL)(condition);}
#define RESULT_CONDITION(condition) ^(id result){return (BOOL)(condition);}
#define RESULT_ERROR_CONDITION(condition) ^(id result, NSError *error){return (BOOL)(condition);}

/*************************************************
* Parameters
*
*	If you don't use helpers methods to creagte promises (search for #PROMISE_HELPER)
*	you may need to pass a lot of parameters to the promise methods.
*	This could be done by these defines due to usually you don't need all of params.
*
**************************************************/
#define StdBlocks FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock
#define AllBlocksWithNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock) FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock
#define BaseBlocks(fulfillBlock, rejectBlock) FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock
#define ProgressCheckBlocks(fulfillBlock, rejectBlock, progressBlock) FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock
#define RejectedCheckBlocks(fulfillBlock, rejectBlock, isRejectedBlock) FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock

#define NoResult SomeVoid *result
#define AnyResult(result) id result

#define ThenParams FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain
#define ElseParams FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *error, id<SomePromiseLastValuesProtocol> lastValuesInChain
#define ThenBlocks FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock
#define ThenParamsNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, result, lastValuesInChain) FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id result, id<SomePromiseLastValuesProtocol> lastValuesInChain
#define ElseParamsNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock, error, lastValuesInChain) FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, NSError *error, id<SomePromiseLastValuesProtocol> lastValuesInChain

#define AlwaysParams id result, NSError *error
#define Always(result, error) id result, NSError *error

#define ResultParams FulfillBlock fulfillBlock, RejectBlock rejectBlock, IsRejectedBlock isRejectedBlock, ProgressBlock progressBlock, id ownerResult, id result, NSError *ownerError, NSError *selfError, id<SomePromiseLastValuesProtocol> lastValuesInChain


//=======================================================================================================================
//*	class SomePromise
//=======================================================================================================================
/*************************************************
* SomePromise is a promise implementation
*
*	It declares some action and has property result and error.
*	If promise's action successfully finished result property will provide the result.
*	In case of promise rejection the error could be found in error property
*	NOTE!: error could be nil in case of rejection.
*	Promise provides status and procentage of it's action.
*
*	Promise provides handles and delegate and observers to get known if promise finished.
*	Promises could be joined in chains.
*
*	Promise contains a SomePromiseFuture object (see SomePromiseFuture.h)
*
*   Search for #PROMISE_HELPER to see the smartest way of using promises.
*
*	ex:
!! 	spTry(^{
!! 			some long action wich takes result == 3
!!	     	return 3;
!!		}).spWhere(RESULT_CONDITION([result integerValue] == 3), ^
!!	  	{
!!		  some long action wich takes result == 5
!!	      return 5;
!!	  	}).onSuccess(^(id result){
!!			do something with result
!!	  	}).onReject(^(NSError *error){
!! 			do something with error
!!	  	}).spThen(^{
!!	  		return; //or maybe just nothing. This will provide SomeVoid instance as a result to the next promise.
!!	  	});
*
*	ex2: We can provide parameters to promise. Just use parameters you need in any order and than provide their values in the same order.
*
!!	spTry(^(NSString *name, Class class){
!!		   return;
!!	}, @"Test_Name", [Void class]).onSuccess(^(id result){
!!	   NSLog(@"P2 success :%@", result);
!!	});
*
*	NOTE!:  Promise will start right after creation.
*			On pending state it stores strong ref to itself befor going to another state.
*			So you can create a promise without storing a ref. to it if you don't need.
*
*			There are posponded promises. they don't start right after creation.
*			They don't have smart(helpers) methods. You can find theit description bellow.
*			Search for #POSTPONDED
**************************************************/
@interface SomePromise<__covariant ObjectType> : NSObject <SomePromiseLastValuesProtocol,
																	OwnerPromiseProtocol,
																 OwnerWhenPromiseProtocol,
																  SomePromiseChainMethods,
														  SomePromiseChainPropertyMethods,
											  SomePromiseChainMethodsExecutorStrategyUser>

/*************************************************
*	status property.
*	Provides current status of the promise.
*
*   ESomePromiseUnknown - just after creation
*   ESomePromiseNonActive - for posponded promises (see below postponded methods)
*   ESomePromisePending - action in progress
*   ESomePromiseSuccess - action finished with result
*   ESomePromiseRejected - action finished with error (could be nil), or promise has been rejected.
**************************************************/
@property (nonatomic, readonly) PromiseStatus status;

/*************************************************
*	result property.
*	Provides the result. Is nil by default.
*	After action finished with success it can not be nil.
*	nil means action has not been finished or error/reject.
*
*	If promise action return nothing (void) the value will be SomeVoid instance.
*	It is represented by Void macro.
*
**************************************************/
@property (nonatomic, readonly) ObjectType _Nullable result;

/*************************************************
* error property.
*	Could be nil even in case of error.
*	Provides NSError representing the reason of promise rejection or
*	action failed.
*
**************************************************/
@property (nonatomic, readonly) NSError *_Nullable error;

/*************************************************
*progress property.
*	provides a progress of the action. Could be not provided ever.
*	It depends on an action.
*
*	progress should be within 0..100
**************************************************/
@property (nonatomic, readonly) float progress; //comletion progress.

/*************************************************
*	promiseThread property.
*	see SomePromiseThread.h
*	You may provide a thread for the action.
*	Here you can get it to provide for the next promise,
*	to be sure they work in the same thread if this is important.
*
*	Could be nil if thread has not been provided.
*	By default promise creates a queue.
*	Also queue could be provided aswell.
*	In both cases this property will return nil
**************************************************/
@property (nonatomic, readonly) SomePromiseThread *promiseThread;

/*************************************************
*	promiseQueue property
*	you may provide a queue for promise.
*	If not and you don't provide a thread, promise will create a queue
*	by default.
*
*	Could return nil if you have provided thread for promise.
*	Will return promise queue and you could provide it to the next promise.
**************************************************/
@property (nonatomic, readonly) dispatch_queue_t promiseQueue;

/*************************************************
*	startSettings property.
*
*	provides full settings list promise has on start.
*	See SomePromiseSettings description in SomePromiseTypes.h
**************************************************/
@property (nonatomic, readonly) SomePromiseSettings *startSettings;

//=======================================================================================================================
//*	class SomePromise. creation methods.
//=======================================================================================================================
// NOTE!: Usually you should use  #PROMISE_HELPER methods instead to create promise.
//

/*************************************************
*	All these methods return new promise
*	The promise starts working and store strong ref. to itself
*	Descriptions will be done only for new parameters, not described before.
**************************************************/

/*************************************************
*	+ (instancetype _Nullable) promiseWithSettings:(SomePromiseSettings *_Nonnull)settings;
*	params:
*		settings - settings for new promise.
*		see SomePromiseSettings in SomePromiseTypes.h
**************************************************/
+ (instancetype _Nullable) promiseWithSettings:(SomePromiseSettings *_Nonnull)settings;

/*************************************************
*	+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
*                                resolvers:(InitBlock _Nonnull) initBlock
*                                    class:(Class _Nullable)class;
*
*	params:
*		name - name of the promise.
*				Could be used for debug.
*				Also you can get a value of promise in chain by it's name.
*		resolvers - is a block wich represents the action. !! See InitBlock in SomePromiseTypes.h
*		class - class of result. This only need to be provided to future object. See SomePromiseFuture.h
*				Usually can be omitted.
* 				Future also use it only in some specifical cases. So usually can be omitted for it too.
**************************************************/
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                resolvers:(InitBlock _Nonnull) initBlock
                                    class:(Class _Nullable)class;

/*************************************************
*		+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
*                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
*								resolvers:(InitBlock _Nonnull) initBlock
*									class:(Class _Nullable)class;
*
*	params:
*		name - see above
* 		delegate - promise delegate. See SomePromiseDelegate in SomePromiseTypes.h
*		resolvers - See above
*		class - see above
*
**************************************************/
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
									class:(Class _Nullable)class;

/*************************************************
*	+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
*                                  onQueue:(dispatch_queue_t _Nullable ) queue
*								resolvers:(InitBlock _Nonnull) initBlock
*								    class:(Class _Nullable)class;
*
*	params:
*		name - see above
* 		onQueue - provides a queue for promise's action.
*		resolvers - See above
*		class - see above
*
**************************************************/
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/*************************************************
*	+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
*                                  onQueue:(dispatch_queue_t _Nullable ) queue
*								resolvers:(InitBlock _Nonnull) initBlock
*								    class:(Class _Nullable)class;
*
*	params:
*		name - see above
* 		onQueue - see above.
*		delegate - see above
*		resolvers - See above
*	delegateQueue - queue for delegate methods to be executed in.
*		class - see above
*
**************************************************/
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

//*** All the same but with thread instead of queue.
// see SomePromiseThread.h fpr more details about SomePromise's thread.
//--with thread

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString *_Nonnull) name
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

//#POSTPONDED
//=======================================================================================================================
//*	class SomePromise. creation methods. Postponded promeses
//=======================================================================================================================
// NOTE!: There are no #PROMISE_HELPER methods for postponded promises.
// NOTE!: Methods are the same as above. The diff. is in the postponded prefix only.
//		  Thus see description above.
/**************************************************************************************
*PostpondedPromises:
*  PostpondedPromise will start (go to pending state) only after user calls start method for it.
*  Note thet in non active state promise does not store strong ref to itself.
***************************************************************************************/

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name //#POSTPONDED
                                resolvers:(InitBlock _Nonnull) initBlock
                                    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name //#POSTPONDED
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name //#POSTPONDED
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name //#POSTPONDED
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name //#POSTPONDED
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

//--with thread

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString*_Nonnull) name //#POSTPONDED
                                 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable ) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name //#POSTPONDED
                                  onThread:(SomePromiseThread *_Nullable ) thread
								resolvers:(InitBlock _Nonnull) initBlock
								    class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name //#POSTPONDED
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name //#POSTPONDED
								 onThread:(SomePromiseThread *_Nullable ) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

/* See above */
+ (instancetype _Nonnull) postpondedPromiseWithName:(NSString *_Nonnull) name //#POSTPONDED
								  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						        resolvers:(InitBlock _Nonnull) initBlock
						            class:(Class _Nullable)class;

//#PREDEFINED
//=======================================================================================================================
//*	class SomePromise. creation methods. predefined promeses
//=======================================================================================================================
// NOTE!: There are no #PROMISE_HELPER methods for postponded promises.
/**************************************************************************************
*predefinedPromises:
*  predefinedPromises will never start. They already have their final state and value or error.
*  Note thet in non active state promise does not store strong ref to itself.
***************************************************************************************/

/**************************************************************************************
*
*	Description for all Methods.
*	Returns predefinedPromise. Success (value) or rejected (error/nil)
*	Depend on what is provided in method
*	name - promise name (see above)
*	value - the success promise will have this value as a result. Could not be nil.
*	delegate - promise delegaete. Delegate methods is not called for predefined promise.
*			   But if you connect promises in chain delegate will be set to the next promise
*			   if you don't use anothe delegate in creation method.
*	delegateThread - To be provided in the next promise in chain.
*	delegateQueue - To be provided in the next promise in chain.
*	class - see above
*	error - create rejected promise with error. Could be nil.
*
**************************************************************************************/
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name //#PREDEFINED
									value:(ObjectType _Nonnull ) object
									class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name //#PREDEFINED
									error:(NSError*_Nullable) error
									class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name //#PREDEFINED
									value:(ObjectType _Nonnull ) object
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						            class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name //#PREDEFINED
									error:(NSError*_Nullable) error
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable ) delegateThread
						            class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name //#PREDEFINED
									value:(ObjectType _Nonnull ) object
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						            class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name //#PREDEFINED
									error:(NSError*_Nullable) error
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						    delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
						            class:(Class _Nullable)class;

//=======================================================================================================================
//*	class SomePromise. creation methods. dependent promeses
//=======================================================================================================================
// NOTE!: Usually you should use  #PROMISE_HELPER methods instead to create dependent promise.
/************************************************************************************************************************
* dependent promises
*   Dependend Promise will be started after the owner promise finished.
*   It has two blocks, one in case of owner success and one in case of owner failed.
*   NOTE!: Even in case of error in owner promise Dependent promise can finish with positive result.
************************************************************************************************************************/
/**************************************************************************************
*
*	Description for all Methods.
*	Returns dependent promise. Success (value) or rejected (error/nil)
*	Depend on what is provided in method
*	name - promise name (see above)
*	ownerPromise - owner promise (or future). Future also could be the promise's owner.
*	futureBlock - the success promise promise block.
*	errorBlock - the reject promise block. Called in case of owner promise finished with no success.
*	delegate - promise delegaete. Delegate methods is not called for predefined promise.
*			   But if you connect promises in chain delegate will be set to the next promise
*			   if you don't use anothe delegate in creation method.
*	delegateThread - To be provided in the next promise in chain.
*	delegateQueue - To be provided in the next promise in chain.
*	class - see above
*
*
**************************************************************************************/

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable) queue
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable) delegateQueue
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable) delegateQueue
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;

//thread
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegatThread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegatThread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable) delegateQueue
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              dependentOn:(id<OwnerPromiseProtocol>_Nonnull) ownerPromise
								  onQueue:(dispatch_queue_t _Nullable) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegatThread
								onSuccess:(FutureBlock _Nonnull) futureBlock
								 onReject:(NoFutureBlock _Nullable) errorBlock
								    class:(Class _Nullable)class;

//=======================================================================================================================
//*	class SomePromise. creation methods. when promeses
//=======================================================================================================================
// NOTE!: Usually you should use  #PROMISE_HELPER methods instead to create when promise.
/************************************************************************************************************************
*    WhenPromise is a promise which can be started only when owner promise is in Pending state.
*    If owner promise is alredy finished (no metter rejected or finished with result) WhenPromise can't
*    be started. It just takes the same state as the owner promise and reprovide it's value or error.
*
*    If owner is a PostpondedPromise, WhenPromise will start after start of the owner promise.
*    Calling start method for the WhenPromise never has any effect.
*
*    When proise can finish only after owner is finished. User must provide additional block
*    which takes both values (from owner and from WhenPromise itself).
*    So this block has 4 additional parameters. two for success cases and two for errors.
*    The final value of the when promise depends exactly on this block.
************************************************************************************************************************/
/**************************************************************************************
*
*	Description for all Methods.
*	Returns when promise.
*	name - promise name (see above)
*	ownerPromise - owner promise (or future).
*	Note!: future can't be the owner for when promise. Tecnically you can pass it, but it has no effect.
*	resolvers - when promise body block. Should run in same time as promise owner
*	errorBlock - the reject promise block. Called in case of owner promise finished with no success.
*	finalBlock - result block. It has result of owner promise and result of when promise and returns the final result.
*	delegate - promise delegaete. Delegate methods is not called for predefined promise.
*			   But if you connect promises in chain delegate will be set to the next promise
*			   if you don't use anothe delegate in creation method.
*	delegateThread - To be provided in the next promise in chain.
*	delegateQueue - To be provided in the next promise in chain.
*	class - see above
*
*	Note!: if when promise has the same thread as it's owner it will be executed after the owner
*	due to two promises can't be executed in one thread at the same time.
*
**************************************************************************************/

/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
									class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class;

//thread
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onThread:(SomePromiseThread *_Nullable) thread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable) finalBlock
							        class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateThread:(SomePromiseThread *_Nullable) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable) finalBlock
							        class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
								 onThread:(SomePromiseThread *_Nullable) thread
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
							delegateQueue:(dispatch_queue_t _Nullable ) delegateQueue
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class;
/* See above */
+ (instancetype _Nonnull) promiseWithName:(NSString*_Nonnull) name
                              whenPromise:(id<OwnerWhenPromiseProtocol>_Nonnull) ownerPromise
                                  onQueue:(dispatch_queue_t _Nullable ) queue
								 delegate:(id<SomePromiseDelegate> _Nullable) delegate
						   delegateThread:(SomePromiseThread *_Nullable) delegateThread
								resolvers:(InitBlock _Nonnull) initBlock
							  finalResult:(FinalResultBlock _Nullable ) finalBlock
							        class:(Class _Nullable)class;

//=======================================================================================================================
//*	class SomePromise. instance methods.
//=======================================================================================================================

/************************************************************************************************************************
*	- (void) start
*	start method starts postponded promise.
*	Note!: you have to store reference to postponded promise (first promise in chain).
*	And call start for it.
*	Note!:Only for postponded promises in nonActive state, no effect in other cases.
************************************************************************************************************************/
- (void) start;

/************************************************************************************************************************
*	- (void) reject
*	Reject promise with standard 'User Rejected' error.
*
*	Note!: After been rejected promise does not stop it's action block execution.
*	Just promise state can't be changed anymore.
*	To stop the promise action you should check promise state inside the promise block and stop it by 'return' in
*	case of rejection.
*
*	example of handling rejection in promise action block:
*
*	[SomePromise promiseWithName:@"Your Promise Name"
*					 resolvers:^(StdBlocks) //StdBlocks contains progressBlock, fulfillBlock and isRejectedBlock
*					 {
*					         int result = 0;
*						     for(int i = 0; i < 20; ++i)
*						     {
*						         sleep(1);
*						         progressBlock(i);
*						         if(isRejectedBlock()) //Here we check if promise is rejected
*						         {
*						            return;
*								 }
*								 result += i;
*							 }
*							 fulfillBlock(@(result));
*					 } class: nil];
*
*	example of handling rejection in ##PROMISE_HELPER methods
*
*	spTry(^(SomeIsRejectedBlockProvider *isRejected){
*
*  			for (int i = 0; i < 100; ++i)
*  			{
*     			if(isRejected.isRejectedBlock()) //check if rejected.
*    			{
*       	 		return 0; //Does not metter what to return. State is already rejected. Promise value will not have this value.
*							//But hte return type shpuld be the same as for success case.
*							//It is rcomended to return 0 or nil in case of any of id return types.
*	 			}
*	 			else
*	 			{
*	    			sleep(1); //to immitate some long action
*	 			}
*  			}
*
*  			return 3; //if not rejected outside - return @(3) as a result. (3 will be cowered to NSNumber automatically).
*  }, isRejectedProvider(), progressProvider());
*
*
*
************************************************************************************************************************/
- (void) reject;

/************************************************************************************************************************
*	- (void) rejectWithError:(NSError* _Nullable) error
*	The same as reject, but with provided error (reject reason).
************************************************************************************************************************/
- (void) rejectWithError:(NSError* _Nullable) error;

//Reject dependant promises.
//Dependences can be rejected only before start. While owner promise is not completed.
//Otherwise you should use ref. to the promice itself and call it's reject method directly.
/************************************************************************************************************************
*	- (void) rejectAllDependences
*	Reject all dependences of the promise.
************************************************************************************************************************/
- (void) rejectAllDependences;

/************************************************************************************************************************
*	- (void) rejectDependencesWithName:(NSString*_Nonnull) name
*	Reject all dependences with name equals to name parameter.
*	Promises could have the same name. So many of dependant promises could have the same name.
*	Dependant promises could have the same name as the owner promise.
*	Owner promise will not be rejected in this case.
*	Note!: By default, if you don't provide subpromise(dependent promise) name it will get the owner name.
*
************************************************************************************************************************/
- (void) rejectDependencesWithName:(NSString*_Nonnull) name;

/************************************************************************************************************************
*	- (void) rejectDependenceByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull promise)) rule
*	Reject all dependences by condition.
*	Parameter rule provides a codition for each promise of all dependences for the owner promise.
*
************************************************************************************************************************/
- (void) rejectDependenceByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull promise)) rule;


//Reject chain
//Promises could be joined in chain.
//Every dependant promise is a part of the chain.
//Chain could also provide rejection methods
/************************************************************************************************************************
*	- (void) rejectAllInChain
*	Reject all promises in chain.
*	The first promise in chain and all it's dependences. Including when promises.
*	Promises already finished with success will not change their state to rejected.
*	So if you have a chain started with already resolved promise (as predefined or just finished) you can use this method
*	to reject all promises in pending state from the chain.
*
*	Rejection in chain could be called by any promise form the chain.
*	Even if you have a ref only to the last promise from the chain all chain could be rejected by calling these methods for
*	this very last promise.
************************************************************************************************************************/
- (void) rejectAllInChain;

/************************************************************************************************************************
*	- (void) rejectAllInChainWithName:(NSString*_Nonnull) name
*	reject all promises with provided name from the chain.
************************************************************************************************************************/
- (void) rejectAllInChainWithName:(NSString*_Nonnull) name;

/************************************************************************************************************************
*	- (void) rejectAllInChainWithName:(NSString*_Nonnull) name
*	reject all promises from the chain wich satisfy the condition.
************************************************************************************************************************/
- (void) rejectAllInChainByRule:(BOOL (^ _Nonnull)(SomePromise * _Nonnull))rule;

//chain thread and queue
/************************************************************************************************************************
*	get/set thread or queue for the promise chain.
*	thread/queue for chain determines how to call listeners methods for chain.
* 	listeners methods could be found bellow.
*	They could be per promise and per chain.
*	Listeners per chain will be called for each promise in chain.
*	These methods provides queue/thread to call these listeners in.
*	Also you could get thread/queue.
* Note!: there could be only queue OR thread.
*	setting thread will also set queue to nil and vice versa.
************************************************************************************************************************/
- (SomePromise *_Nonnull) setChainThread:(SomePromiseThread*_Nullable)thread;
- (SomePromiseThread *_Nullable)getChainThread;
- (SomePromise *_Nonnull) setChainQueue:(dispatch_queue_t _Nullable)queue;
- (dispatch_queue_t _Nullable)getChainQueue;

//provide chain thread and queue block setter
//ex: promise.setChainThread(thread);
- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread*_Nullable))setChainThread;
- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable))setChainQueue;

//Observers.
/************************************************************************************************************************
*
*	Each promise could have many observers.
*	Observers are just the same as a delegate. But there could be many of them.
*	Each observer could has it's own queu/thread.
*	Observer could be added or removed.
* 	Note!: These methods don't touch the delegate.
*
************************************************************************************************************************/
- (SomePromise *_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise *_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) queue;
- (SomePromise *_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread;
- (SomePromise *_Nonnull) addObserverOnMain:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise *_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers;
- (SomePromise *_Nonnull) addObserversOnMain:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers;
- (SomePromise *_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers onQueue:(dispatch_queue_t _Nullable) queue;
- (SomePromise *_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers onThread:(SomePromiseThread *_Nonnull) thread;
- (SomePromise *_Nonnull) removeObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise *_Nonnull) removeObservers;

//The same, but provide blocks to set observers.
// ex: promise.addObserver(observer);
- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))addObserver;
- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, id<SomePromiseObserver> _Nonnull))addObserverOnQueue;
- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, id<SomePromiseObserver> _Nonnull))addObserverOnThread;
- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))addObserverOnMain;
- (SomePromise *_Nonnull (^ __nonnull)(NSArray<id<SomePromiseObserver>> *_Nonnull))addObservers;
- (SomePromise *_Nonnull (^ __nonnull)(NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnMain;
- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnQueue;
- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnThread;
- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))removeObserver;
- (SomePromise *_Nonnull (^ __nonnull)(void))removeAllObservers;

/************************************************************************************************************************
*
*	Promise chain could have many observers.
*	Observer for chain is an observer for each promise in the chain.
*	Observers are just the same as a delegate. But there could be many of them.
*	Each observer could has it's own queu/thread.
*	Observer could be added or removed.
* 	Note!: These methods don't touch the delegate.
*
************************************************************************************************************************/
- (SomePromise *_Nonnull) addChainObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) _queue;
- (SomePromise *_Nonnull) addChainObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread;
- (SomePromise *_Nonnull) removeChainObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise *_Nonnull) removeChainObservers;

//The same, but provide blocks to set observers.
// ex: promise.addChainObserver(observer);
- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, id<SomePromiseObserver> _Nonnull))addChainObserver;
- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, id<SomePromiseObserver> _Nonnull))addChainObserverOnThread;
- (SomePromise *_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))removeChainObserver;
- (SomePromise *_Nonnull (^ __nonnull)(void))removeAllObserversinChain;

//Timeout.
//Each promise could have a timeout. It will be autorejected if timeout reached.
//Note!: promise action is not automatically stopped. See reject methods for more details.
/************************************************************************************************************************
* - (void) addTimeout:(NSTimeInterval)timeout
*	Adds timeout to the promise
************************************************************************************************************************/
- (void) addTimeout:(NSTimeInterval)timeout;

/************************************************************************************************************************
* - (SomePromise *_Nonnull)timeout:(NSTimeInterval)timeout
*	Adds timeout to the promise and returns ref. to the promise (self).
*	This allows to proceed promise chain.
************************************************************************************************************************/
- (SomePromise *_Nonnull)timeout:(NSTimeInterval)timeout;

/************************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(NSTimeInterval))addTimeout
*	Returns a block wich adds timeout to the promise.
*	Block returns ref to the promise and allows to proceed promise chain.
*
*	ex: promise.addTimeout(12);
************************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(NSTimeInterval))addTimeout;

/************************************************************************************************************************
* - (SomePromise *_Nonnull)removeTimeout
*	removes timeout. If promise is in pending state.
*	returns ref to the promise.
*	Allows to proceed promise chain.
************************************************************************************************************************/
- (SomePromise *_Nonnull)removeTimeout;

/************************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(void))declineTimeout;
*	returns block removing timeout. If promise is in pending state.
*	ex: promise.declineTimeout();
************************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(void))declineTimeout;

//Listeners queue/thread
//These methods could change queue/thread used for calling listeners for promise.
//They don't change queue/thread for promise observers or delegate.
/************************************************************************************************************************
* - (void) addObserversQueue:(dispatch_queue_t _Nonnull) queue
*	All listeners for promise will be called from the queue.
************************************************************************************************************************/
- (void) addObserversQueue:(dispatch_queue_t _Nonnull) queue;

/************************************************************************************************************************
* - (void) addObserversThread:(SomePromiseThread *_Nonnull) thread
*	All listeners for promise will be called from the thread.
************************************************************************************************************************/
- (void) addObserversThread:(SomePromiseThread *_Nonnull) thread;

/************************************************************************************************************************
* - (SomePromise *_Nonnull) observersQueue:(dispatch_queue_t _Nonnull) queue
*	All listeners for promise will be called from the queue.
*	Returns ref to the promise. Allows to proceed chain
************************************************************************************************************************/
- (SomePromise *_Nonnull) observersQueue:(dispatch_queue_t _Nonnull) queue;

/************************************************************************************************************************
* - (SomePromise *_Nonnull) observersThread:(SomePromiseThread *_Nonnull) thread
*	All listeners for promise will be called from the thread.
*	Returns ref to the promise. Allows to proceed chain
************************************************************************************************************************/
- (SomePromise *_Nonnull) observersThread:(SomePromiseThread *_Nonnull) thread;

/************************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t  _Nonnull)) observersQueue
*	Returns a block wich could change listenres's queue.
*	Block description:
*	All listeners for promise will be called from the queue.
*	Returns ref to the promise. Allows to proceed chain
************************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(dispatch_queue_t  _Nonnull)) observersQueue;

/************************************************************************************************************************
* - (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread  *_Nonnull)) observersThread
*	Returns a block wich could change listenres's thread.
*	Block description:
*	All listeners for promise will be called from the thread.
*	Returns ref to the promise. Allows to proceed chain
************************************************************************************************************************/
- (SomePromise *_Nonnull (^ __nonnull)(SomePromiseThread  *_Nonnull)) observersThread;

//Listeners.
//Listeners are blocks wich will be called on promise's events
/************************************************************************************************************************
* - (void) addOnSuccess:(OnSuccessBlock _Nonnull) body
* provides on success listener
************************************************************************************************************************/
- (void) addOnSuccess:(OnSuccessBlock _Nonnull) body;

/************************************************************************************************************************
* - (void) addOnReject:(OnRejectBlock _Nonnull) body
* provides on reject listener
************************************************************************************************************************/
- (void) addOnReject:(OnRejectBlock _Nonnull) body;

/************************************************************************************************************************
* - (void) addOnProgress:(OnProgressBlock _Nonnull) body
* provides on progress listener
************************************************************************************************************************/
- (void) addOnProgress:(OnProgressBlock _Nonnull) body;

//These methods are the same as above. But they also returns ref to the promise. Allows to proceed chain.
- (SomePromise *_Nonnull) onSuccess:(OnSuccessBlock _Nonnull) body;
- (SomePromise *_Nonnull) onReject:(OnRejectBlock _Nonnull) body;
- (SomePromise *_Nonnull) onProgress:(OnProgressBlock _Nonnull) body;

//These methods provide listeners for chain. It means they will be called for  each promise in chain.
//queue/thread for them could be provided in setChainThread/setChainQueue
- (SomePromise *_Nonnull) onEachSuccess:(onEachSuccessBlock _Nonnull) body;
- (SomePromise *_Nonnull) onEachReject:(OnEachRejectBlock _Nonnull) body;
- (SomePromise *_Nonnull) onEachProgress:(OnEachProgressBlock _Nonnull) body;

//The same as above.
// But they provide blocks to be called to set listeners.
// Could be called like so
// promise.onSuccess(^(id result){
// //handlong
// });
- (SomePromise *_Nonnull (^ __nonnull)(OnSuccessBlock _Nonnull)) onSuccess;
- (SomePromise *_Nonnull (^ __nonnull)(OnRejectBlock _Nonnull)) onReject;
- (SomePromise *_Nonnull (^ __nonnull)(OnProgressBlock _Nonnull)) onProgress;

//The same but for chain.
- (SomePromise *_Nonnull (^ __nonnull)(onEachSuccessBlock _Nonnull))onEachSuccess;
- (SomePromise *_Nonnull (^ __nonnull)(OnEachRejectBlock _Nonnull))onEachReject;
- (SomePromise *_Nonnull (^ __nonnull)(OnEachProgressBlock _Nonnull))onEachProgress;

/************************************************************************************************************************
* - (id _Nullable) lastResultInChain
* provides the last success result in chain.
************************************************************************************************************************/
- (id _Nullable) lastResultInChain;

/************************************************************************************************************************
* -  (NSError *_Nullable) lastErrorInChain
* provides the last error result in chain. Could be nil even if there were rejections.
************************************************************************************************************************/
-  (NSError *_Nullable) lastErrorInChain;

/************************************************************************************************************************
* - (SomePromiseFuture *_Nullable) getFuture
* Returns SomePromiseFuture object corresponds to this promise.
************************************************************************************************************************/
- (SomePromiseFuture *_Nullable) getFuture;

/************************************************************************************************************************
* - (SomePromiseSettings*) settings
* Returns current promise settings.
************************************************************************************************************************/
- (SomePromiseSettings*) settings;

//Retry. Each promise could be autoretry in case of rejection (internal in block).
//If it is rejected by calling reject method outside it will not be retry.

//- (SomePromise*)retryWithNumbers:(NSInteger)maxRetryAmount
//Provides maximum retrying numbers for the promise. Promise will be rejected if no success for all attempts.
- (SomePromise*)retryWithNumbers:(NSInteger)maxRetryAmount;
//Provides a condition to check if need to retry.
- (SomePromise*)retryWhileCondition:(BOOL (^ _Nonnull)(void))condition;
// retry only once. The same as call retryWithNumbers:1
- (SomePromise*)retryOnce;
// rtry as many times as needed. No limitations. Could be rejected by reject method
- (SomePromise*)retryInfinity;

//Retry blocks. returns Blocks to set retry.
- (SomePromise *_Nonnull (^ __nonnull)(NSInteger))retry;
- (SomePromise *_Nonnull (^ __nonnull)(BOOL (^ _Nonnull)(void)))retryWhile;

@end

#pragma mark -
#pragma mark Helper
//this helper provides #PROMISE_HELPER method for creation first promise in chain.
//And method to get result with waiting. Thread is blocked untill the result get ready.
//Other helper methods are located in SomePromiseTypes.h and are marked as #PROMISE_HELPER
typedef id hPromise;
//hPromise could be used to create a promise action block.
//It does not run the promise and does not provide parameters to it.
//It is an alternative topostponded promises.
hPromise hPromise_create(id creationBlock);
//spTry is a helper (#PROMISE_HELPER) method to create the first promise in chain.
/***********************************************************************************************************************************
* SomePromise* spTry(hPromise creationBlock, ...);
* Returns new promise.
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
*************************************************************************************************************************************/
SomePromise* spTry(hPromise creationBlock, ...); //#PROMISE_HELPER

//Reject promise with error.
void spReject(NSError *error); //#PROMISE_HELPER

@interface SomePromise (SomePromise_Helper)

/***********************************************************************************************************************************
*	- (id _Nullable) get
*
*	Just make a call 'get' for promise's future objec.
*	Thread is waiting untill promise get resolved (reject or success).
*	If promise is already resolved - returns the result.
* 	If returns NSError or nil - means promise rejected.
*	Any other value - success.
*************************************************************************************************************************************/
- (id _Nullable) get; //#PROMISE_HELPER
@end
