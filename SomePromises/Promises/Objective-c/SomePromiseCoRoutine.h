//
//  SomePromiseCoRoutine.h
//  SomePromises
//
//  Created by Sergey Makeev on 15/04/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SomePromiseGenerator.h"

NS_ASSUME_NONNULL_BEGIN

typedef  id _Nullable (^SPRoutine)(id _Nullable value);

@class SomePromiseThread;

@interface RoutineState: NSObject

@property (nonatomic, readonly)        SPGenerator *generator;
@property (nonatomic, readonly, copy)  SPRoutine   routine;
@property (nonatomic, readonly)        NSInteger      step;
@property (nonatomic, readonly)        NSTimeInterval timeinterval;

- (instancetype) initWithGenerator:(SPGenerator*) generator                                      routine:(SPRoutine) routine;
- (instancetype) initWithGenerator:(SPGenerator*) generator step:  (NSInteger)      step         routine:(SPRoutine) routine;
- (instancetype) initWithGenerator:(SPGenerator*) generator delta: (NSTimeInterval) timeinterval routine:(SPRoutine) routine;

@end

@interface SPCoRoutine : NSObject

@property (readonly)            BOOL isCancelled;
@property (readonly)            BOOL isDone;
@property (nonatomic, readonly) BOOL isActive;

@property (nonatomic, readonly) NSArray * _Nullable results;

- (instancetype) initWihStates:(NSArray<RoutineState*>*) states;
- (instancetype) initWihStates:(NSArray<RoutineState*>*) states queue: (dispatch_queue_t)   queue;
- (instancetype) initWihStates:(NSArray<RoutineState*>*) states thread:(SomePromiseThread*) thread;

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators                               andRoutine:(SPRoutine) routine;
- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators delta: (NSTimeInterval) delta andRoutine:(SPRoutine) routine;
- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators step:  (NSInteger)      step  andRoutine:(SPRoutine) routine;

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators queue: (dispatch_queue_t) queue                               andRoutine:(SPRoutine) routine;
- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators queue: (dispatch_queue_t) queue delta: (NSTimeInterval) delta andRoutine:(SPRoutine) routine;
- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators queue: (dispatch_queue_t) queue step:  (NSInteger)      step  andRoutine:(SPRoutine) routine;

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators thread:(SomePromiseThread*) thread                               andRoutine:(SPRoutine) routine;
- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators thread:(SomePromiseThread*) thread delta: (NSTimeInterval) delta andRoutine:(SPRoutine) routine;
- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators thread:(SomePromiseThread*) thread step:  (NSInteger)      step  andRoutine:(SPRoutine) routine;

- (void) setQueue :(dispatch_queue_t)   operationQueue;
- (void) setThread:(SomePromiseThread*) operationThread;
- (void) cancel;
- (void) run;

@end

NS_ASSUME_NONNULL_END
