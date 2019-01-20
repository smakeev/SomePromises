//
//  SomePromiseFuture.h
//  SomePromises
//
//  Created by Sergey Makeev on 23/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SomePromiseInternals.h"
#import "SomePromiseTypes.h"
#import "SomePromiseChainMethodsExecutorStrategy.h"

@class SomePromiseThread;
@class SomePromise;
@class SomeListener;


//=======================================================================================================================
//*	class SomePromiseFuture represents a future object.
//
//	Usually it is used as a part of SomePromise but can be used indepently.
//	Futer is a simple container of some value or error. It can be resolved (has error or value)
//	Or not resolved (waiting for value).
//	Future can be asked for value/error, or listeners could be used. Also you can add promises directly to the future.
//  They will work like dependant promises and will be started after future get resolved.
//	Also if provide future class it is possible to use future as if it is it's value
//	Call all values instances methods while future is not resolved yet.
//	This calls will be performed in future thread/queue right after future resolved.
//=======================================================================================================================
@interface SomePromiseFuture<__covariant ObjectType> : NSProxy <OwnerPromiseProtocol,
                                                            OwnerWhenPromiseProtocol,
															 SomePromiseChainMethods,
													 SomePromiseChainPropertyMethods,
										 SomePromiseChainMethodsExecutorStrategyUser>

//is used to provide method calls for future as for it's value.
//ex:
//	Let's say there is some TestClass with voidReturn
//
//	SomePromiseFuture<TestClass*> *future = [[SomePromiseFuture alloc] initWithThread:thread class:[TestClass class]];
//    TestClass *number = [future getFuture];
//
//    [number voidReturn];
//    [number voidReturn];
//    [number voidReturn];
//
//	Note!: method should return void. In case of not void return it's return can not be received.
//	This will provide warning in console.
@property (nonatomic, assign)Class currentClass;

//Init methods. Could have thread/queue and class as parameters.
//By default does not need any parameters.
//Class could be provided as nil.
//By default future will create it's queue.
- (instancetype _Nonnull) init;
- (instancetype _Nonnull) initWithClass:(Class _Nullable)class;
- (instancetype _Nonnull) initWithQueue:(dispatch_queue_t _Nullable)queue class:(Class _Nullable)class;
- (instancetype _Nonnull) initWithThread:(SomePromiseThread *_Nullable)thread  class:(Class _Nullable)class;

/***********************************************************************************************************
*	- (void) resolveWithObject:(ObjectType _Nonnull)object
*	provides object as a result for future.
*	Note!: if future is a part of a promise you can't resolve it by this method.
* 	Will have no effect.
*	Note!: future can be resolved only once. Will no effect for the second call.
************************************************************************************************************/
- (void) resolveWithObject:(ObjectType _Nonnull)object;

/***********************************************************************************************************
*	- (void) resolveWithError:(NSError *_Nullable)error
*	provides error as a result for future.
*	Note!: if future is a part of a promise you can't resolve it by this method.
* 	Will have no effect.
*	Note!: future can be resolved only once. Will no effect for the second call.
************************************************************************************************************/
- (void) resolveWithError:(NSError *_Nullable)error;

/***********************************************************************************************************
*	- (BOOL) isResolved
*	YES if has error or result.
************************************************************************************************************/
- (BOOL) isResolved;

/***********************************************************************************************************
*	- (BOOL) hasError
*	YES if has error
************************************************************************************************************/
- (BOOL) hasError;

/***********************************************************************************************************
*	- (BOOL) hasResult
*	YES if has result.
************************************************************************************************************/
- (BOOL) hasResult;

/***********************************************************************************************************
*	- (ObjectType _Nullable) getFuture;
*	could return future object (value of ClassBox), or self (SomePromiseFuture) if future is not resolved.
*	In case of error will return nil.
************************************************************************************************************/
- (ObjectType _Nullable) getFuture;

/***********************************************************************************************************
*	- (NSError *_Nullable) getError
*	could return nil, if future is not resolved or resolved with value.
*	In case of error will return it.
************************************************************************************************************/
- (NSError *_Nullable) getError;

/***********************************************************************************************************
*	- (ObjectType _Nullable) get
* 	get  synchroniusly waits while future be resolved.
* 	will return future object or error. Could return nil due to error could be nil.
************************************************************************************************************/
- (ObjectType _Nullable) get;

/***********************************************************************************************************
*	- (void (^ __nonnull)(id _Nonnull, void (^SPListener)(ObjectType _Nullable)))bind;
*	Call SPListener block with current value and after value changed
************************************************************************************************************/
- (void (^ __nonnull)(id _Nonnull, void (^SPListener)(ObjectType _Nullable)))bind;

/***********************************************************************************************************
*	- (void (^ __nonnull)(id _Nonnull, void (^SPListener)(NSError *_Nullable)))bindError;
*	Call SPListener block with current error and after error changed.
************************************************************************************************************/
- (void (^ __nonnull)(id _Nonnull, void (^SPListener)(NSError *_Nullable)))bindError;

/***********************************************************************************************************
*	- (void) unbind:(id _Nonnull )object;
*	Stop listening for value changed
************************************************************************************************************/
- (void) unbind:(id _Nonnull )object;

/***********************************************************************************************************
*	- (void) unbindError:(id _Nonnull )object;
*	Stop listening for error changed
************************************************************************************************************/
- (void) unbindError:(id _Nonnull )object;

/***********************************************************************************************************
*	- (void) addValueListener:(SomeListener *_Nonnull)listener;
*	listener start listening to value changes
************************************************************************************************************/
- (void) addValueListener:(SomeListener *_Nonnull)listener;

/***********************************************************************************************************
*	- (void) removeValueListener:(SomeListener *_Nonnull)listener
*	listener to stop listening to value changes
************************************************************************************************************/
- (void) removeValueListener:(SomeListener *_Nonnull)listener;

/***********************************************************************************************************
*	- (void) addErrorListener:(SomeListener *_Nonnull)listener
*	listener start listening to error changes
************************************************************************************************************/
- (void) addErrorListener:(SomeListener *_Nonnull)listener;

/***********************************************************************************************************
*	- (void) removeErrorListener:(SomeListener *_Nonnull)listener;
*	listener to stop listening to error changes
************************************************************************************************************/
- (void) removeErrorListener:(SomeListener *_Nonnull)listener;

/***********************************************************************************************************
*	- (void) stopAllTasks
*	Don't call methods for value, provided by future.
************************************************************************************************************/
- (void) stopAllTasks;

/***********************************************************************************************************
*	- (void) rejectAllDependences
*	Reject all promises in chain starting from the future.
************************************************************************************************************/
- (void) rejectAllDependences;

/***********************************************************************************************************
*	addPromise methods group.
*	Provide promise to start after future resolved.
*	Usually #PROMISE_HELPER methods could be used instead.
************************************************************************************************************/
- (SomePromise*) addPromiseWithName:(NSString*)name success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate ddelegateThread:(SomePromiseThread *_Nullable)delegateThread success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue success:(FutureBlock _Nonnull) futureBlock rejected:(NoFutureBlock _Nonnull) rejectedBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onQueue:(dispatch_queue_t _Nullable)queue withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateThread:(SomePromiseThread *_Nullable)delegateThread resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
- (SomePromise*) addWhenPromiseWithName:(NSString*)name onThread:(SomePromiseThread *_Nullable)thread withDelegate:(id<SomePromiseDelegate> _Nullable) delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue resolvers:(InitBlock _Nonnull) initBlock finalResult:(FinalResultBlock _Nonnull) finalBlock class:(Class _Nullable)class;
@end
