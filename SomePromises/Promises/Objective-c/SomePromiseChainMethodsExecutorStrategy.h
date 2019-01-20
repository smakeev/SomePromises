//
//  SomePromiseChainMethodsExecutorStrategy.h
//  SomePromises
//
//  Created by Sergey Makeev on 25/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

/******
*
*	This is default implementation of SomePromiseChainMethods and SomePromiseChainPropertyMethods protocols
*	It is used by SomePromise and SomePromiseFuture.
*	They both conforms to SomePromiseChainMethodsExecutorStrategyUser
*	(see SomePromiseUtils.h makeProtocolOriented method description for more details)
*	Description of methods provided here could be found inside SomePromise and SomePromiseFuture headers or inside SomePromiseTypes.h.
******/

#import <Foundation/Foundation.h>
#import "SomePromiseTypes.h"
#import "SomePromiseInternals.h"

@class _InternalChainHandler;
@class SomePromiseThread;
@protocol SomePromiseDelegate;

//=======================================================================================================================
//*	@protocol SomePromiseChainMethodsExecutorStrategyUser
//=======================================================================================================================
//
//	This is a protocol to represent type restrictions for default implementations of SomePromiseChainMethods and SomePromiseChainPropertyMethods
//
@protocol SomePromiseChainMethodsExecutorStrategyUser <OwnerPromiseProtocol,
                                                   OwnerWhenPromiseProtocol,
                                                    SomePromiseChainMethods,
											SomePromiseChainPropertyMethods>

@property (nonatomic, readonly) _InternalChainHandler *chain;
@property (nonatomic, readonly) SomePromiseThread *delegateThread;
@property (nonatomic, readonly) NSString *_Nonnull name;
@property (nonatomic, readonly, weak) id<SomePromiseDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegatePromiseQueue;

@optional //Note, Future Object does not support these methods.

- (void) addOnSuccess:(OnSuccessBlock _Nonnull) body;
- (void) addOnReject:(OnRejectBlock _Nonnull) body;
- (void) addOnProgress:(OnProgressBlock _Nonnull) body;

- (SomePromise*_Nonnull) onSuccess:(OnSuccessBlock _Nonnull) body;
- (SomePromise*_Nonnull) onReject:(OnRejectBlock _Nonnull) body;
- (SomePromise*_Nonnull) onProgress:(OnProgressBlock _Nonnull) body;
- (SomePromise*_Nonnull) onEachSuccess:(onEachSuccessBlock _Nonnull) body;
- (SomePromise*_Nonnull) onEachReject:(OnEachRejectBlock _Nonnull) body;
- (SomePromise*_Nonnull) onEachProgress:(OnEachProgressBlock _Nonnull) body;

- (SomePromise*_Nonnull (^ __nonnull)(OnSuccessBlock _Nonnull)) onSuccess;
- (SomePromise*_Nonnull (^ __nonnull)(OnRejectBlock _Nonnull)) onReject;
- (SomePromise*_Nonnull (^ __nonnull)(OnProgressBlock _Nonnull)) onProgress;
- (SomePromise*_Nonnull (^ __nonnull)(onEachSuccessBlock _Nonnull))onEachSuccess;
- (SomePromise*_Nonnull (^ __nonnull)(OnEachRejectBlock _Nonnull))onEachReject;
- (SomePromise*_Nonnull (^ __nonnull)(OnEachProgressBlock _Nonnull))onEachProgress;

- (SomePromise*_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise*_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) queue;
- (SomePromise*_Nonnull) addObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread;
- (SomePromise*_Nonnull) addObserverOnMain:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise*_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers;
- (SomePromise*_Nonnull) addObserversOnMain:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers;
- (SomePromise*_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers onQueue:(dispatch_queue_t _Nullable) queue;
- (SomePromise*_Nonnull) addObservers:(NSArray<id<SomePromiseObserver>> *_Nonnull) observers onThread:(SomePromiseThread *_Nonnull) thread;
- (SomePromise*_Nonnull) removeObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise*_Nonnull) removeObservers;

- (SomePromise*_Nonnull) addChainObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) _queue;
- (SomePromise*_Nonnull) addChainObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread;
- (SomePromise*_Nonnull) removeChainObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (SomePromise*_Nonnull) removeChainObservers;

- (SomePromise*_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, id<SomePromiseObserver> _Nonnull))addChainObserver;
- (SomePromise*_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, id<SomePromiseObserver> _Nonnull))addChainObserverOnThread;
- (SomePromise*_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))removeChainObserver;
- (SomePromise*_Nonnull (^ __nonnull)(void))removeAllObserversinChain;

- (SomePromise*_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))addObserver;
- (SomePromise*_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, id<SomePromiseObserver> _Nonnull))addObserverOnQueue;
- (SomePromise*_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, id<SomePromiseObserver> _Nonnull))addObserverOnThread;
- (SomePromise*_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))addObserverOnMain;
- (SomePromise*_Nonnull (^ __nonnull)(NSArray<id<SomePromiseObserver>> *_Nonnull))addObservers;
- (SomePromise*_Nonnull (^ __nonnull)(NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnMain;
- (SomePromise*_Nonnull (^ __nonnull)(dispatch_queue_t _Nullable, NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnQueue;
- (SomePromise*_Nonnull (^ __nonnull)(SomePromiseThread *_Nullable, NSArray<id<SomePromiseObserver>> *_Nonnull))addObserversOnThread;
- (SomePromise*_Nonnull (^ __nonnull)(id<SomePromiseObserver> _Nonnull))removeObserver;
- (SomePromise*_Nonnull (^ __nonnull)(void))removeAllObservers;

- (id _Nullable) lastResultInChain;
-  (NSError *_Nullable) lastErrorInChain;

@end

//=======================================================================================================================
//*	class SomePromiseChainMethodsExecutorStrategy
//=======================================================================================================================
//
//	This is a stab class to provide default implementtions for SomePromiseChainMethods and SomePromiseChainPropertyMethods protocols
//
@interface SomePromiseChainMethodsExecutorStrategy : NSObject <SomePromiseChainMethods, SomePromiseChainPropertyMethods, SomePromiseChainMethodsExecutorStrategyUser>

@end
