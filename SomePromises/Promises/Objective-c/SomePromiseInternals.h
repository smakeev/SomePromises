//
//  SomePromiseInternals.h
//  SomePromises
//
//  Created by Sergey Makeev on 25/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//


////
// Here is some internal part. No description provided.
////

#import "SomePromiseTypes.h"

#ifndef SomePromiseInternals_h
#define SomePromiseInternals_h
@class _InternalChainHandler;

@protocol OwnerPromiseProtocol <NSObject>
@required
- (void) privateAddToDependancy:(id<DependentPromiseProtocol>) dependee;
@property (nonatomic, readonly) _InternalChainHandler *chain;
@end

@protocol WhenPromiseProtocol; 
@protocol OwnerWhenPromiseProtocol <NSObject>
@required
- (void) privateAddWhen:(id<WhenPromiseProtocol>) when;
@property (nonatomic, readonly) _InternalChainHandler *chain;
@property (nonatomic, readonly) PromiseStatus status;
- (id _Nullable) getFuture;
@end

@interface ObserverAsyncWayWrapper : NSObject

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) SomePromiseThread *thread;

@end

@interface _InternalChainHandler : NSObject <SomePromiseLastValuesProtocol>
{
   dispatch_queue_t _internalQueue;
   dispatch_queue_t _defaultQueue;
   NSMutableArray<OnSuccessBlock> *_eachPromiseOnSuccessBlocks;
   NSMutableArray<OnRejectBlock> *_eachPromiseOnRejectBlocks;
   NSMutableArray<OnProgressBlock> *_eachPromiseOnProgressBlocks;
   NSMapTable<id<SomePromiseObserver>, ObserverAsyncWayWrapper*> *_chainObservers;
   NSHashTable*_promises;
   NSMutableDictionary<NSString*, id> *_valuesForName;
	
   id _lastResult;
   NSError *_lastError;
	
   SomePromiseThread *_thread;
}

@property (nonatomic, readonly) id lastResult;
@property (nonatomic, readonly) NSError *lastError;

@property (atomic) SomePromiseThread *thread;
@property (atomic) dispatch_queue_t queue;

- (instancetype) initWithPromise:(SomePromise*)promise;

- (void) addObserver:(id<SomePromiseObserver> _Nonnull) observer onQueue:(dispatch_queue_t _Nullable) queue;
- (void) addObserver:(id<SomePromiseObserver> _Nonnull) observer onThread:(SomePromiseThread *_Nonnull) thread;
- (void) removeObserver:(id<SomePromiseObserver> _Nonnull) observer;
- (void) removeObservers;

- (void) addOnSuccess:(onEachSuccessBlock _Nonnull) body;
- (void) addOnReject:(OnEachRejectBlock _Nonnull) body;
- (void) addOnProgress:(OnEachProgressBlock _Nonnull) body;

- (id) valueByName:(NSString*) name;

//observers to start
- (void) promise:(SomePromise *_Nonnull) promise gotResult:(id _Nonnull ) result;
- (void) promise:(SomePromise *_Nonnull) promise rejectedWithError:(NSError *_Nullable) error;
- (void) promise:(SomePromise *_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus;
- (void) promise:(SomePromise *_Nonnull) promise progress:(float) progress;

@end

typedef void(^DeferBlock)(void);
//for defer
id getDeferTagByName(NSString *tagName);
void addBlockToTagWithNumber(id tag, int number, DeferBlock block);
void addBlockToPoolWithTagName(int number, DeferBlock block, NSString *tagName);
//for deferTag
BOOL areThereBlocksForTagWithName(NSString *tagName);
void addAllBlocksToTagForTagWithName(id deferTag, NSString *tagName);
void storeTag(id deferTag, NSString *tagName);

@interface DeferPools : NSObject
+ (instancetype) instance;
@property(nonatomic)NSLock *somePromiseDeferLocker;
@end

@interface Defer : NSObject
+ (instancetype)block:(void(^)(void))block;
- (void) doNothing;
@end


#endif /* SomePromiseInternals_h */
