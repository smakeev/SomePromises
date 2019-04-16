//
//  SomePromiseCoRoutine.m
//  SomePromises
//
//  Created by Sergey Makeev on 15/04/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "SomePromiseCoRoutine.h"
#import "SomePromiseThread.h"

@interface RoutineState ()
{
	SPGenerator    *_generator;
	SPRoutine      _routine;
	NSInteger      _step; //step in each generator;
	NSTimeInterval _timeInterval;
	BOOL           _finished;
}

@property (nonatomic)        SPGenerator    *generator;
@property (nonatomic, copy)  SPRoutine      routine;
@property (nonatomic)        NSInteger      step;
@property (nonatomic)        NSTimeInterval timeinterval;

@property (nonatomic)        BOOL           finished;

@end

@implementation RoutineState
@synthesize generator = _generator;
@synthesize finished  = _finished;

- (instancetype) initWithGenerator:(SPGenerator*) generator routine:(SPRoutine) routine {
	self = [super init];
	if (self) {
		self.generator = generator;
		self.routine   = routine;
	}
	return self;
}

- (instancetype) initWithGenerator:(SPGenerator*) generator step:(NSInteger) step routine:(SPRoutine) routine {
	self = [self initWithGenerator:generator routine:routine];
	if (self) {
		self.step = step;
	}
	return self;
}

- (instancetype) initWithGenerator:(SPGenerator*) generator delta:(NSTimeInterval) timeinterval routine:(SPRoutine) routine {
	self = [self initWithGenerator:generator routine:routine];
	if (self) {
		self.timeinterval = timeinterval;
	}
	return self;
}

@end

@interface SPCoRoutine()
{
	NSInteger                _finishedIterators;
	NSInteger                _index; //current generator index.
	NSArray<RoutineState*>   *_generators;
	BOOL                     _isCancelled;
	BOOL                     _isDone;
	BOOL                     _inProgress;
	dispatch_queue_t         _operationQueue;
	SomePromiseThread        *_operatioThread;
	NSMutableArray           *_routineResults;
}

@property (atomic, readwrite) BOOL isCancelled;
@property (atomic, readwrite) BOOL isDone;

@end

@interface SPCoRoutine (private)

- (void) _run;
- (void) _updateIndex;

@end

@implementation SPCoRoutine
@synthesize isCancelled = _isCancelled;
@synthesize isDone      = _isDone;
@synthesize isActive  = _inProgress;

- (instancetype) initWihStates:(NSArray<RoutineState*>*) states {
	self = [super init];
	if (self) {
		_generators = [states copy];
		_routineResults = [NSMutableArray new];
		_operationQueue = dispatch_get_main_queue();
	}
	return self;
}

- (instancetype) initWihStates:(NSArray<RoutineState*>*)states queue:(dispatch_queue_t) queue {
	self = [self initWihStates:states];
	if (self) {
		[self setQueue:queue];
	}
	return self;
}

- (instancetype) initWihStates:(NSArray<RoutineState*>*)states thread:(SomePromiseThread*) thread {
	self = [self initWihStates:states];
	if (self) {
		[self setThread:thread];
	}
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators andRoutine:(SPRoutine) routine {

	NSMutableArray *array = [NSMutableArray new];
	for (SPGenerator *generator in generators) {
		RoutineState *state = [[RoutineState alloc] initWithGenerator:generator routine: routine];
		[array addObject:state];
	}
	self = [self initWihStates:array];

	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators delta: (NSTimeInterval) delta andRoutine:(SPRoutine) routine {

	NSMutableArray *array = [NSMutableArray new];
	for (SPGenerator *generator in generators) {
		RoutineState *state = [[RoutineState alloc] initWithGenerator:generator delta: delta routine: routine];
		[array addObject:state];
	}
	self = [self initWihStates:array];

	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators step: (NSInteger) step andRoutine:(SPRoutine) routine {

	NSMutableArray *array = [NSMutableArray new];
	for (SPGenerator *generator in generators) {
		RoutineState *state = [[RoutineState alloc] initWithGenerator:generator step: step routine: routine];
		[array addObject:state];
	}
	self = [self initWihStates:array];
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators queue: (dispatch_queue_t) queue andRoutine:(SPRoutine) routine {
	self = [self initWithGenerators: generators andRoutine: routine];
	[self setQueue: queue];
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators queue: (dispatch_queue_t) queue delta: (NSTimeInterval) delta andRoutine:(SPRoutine) routine {
	self = [self initWithGenerators: generators delta: delta andRoutine: routine];
	[self setQueue: queue];
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators queue: (dispatch_queue_t) queue step: (NSInteger) step andRoutine:(SPRoutine) routine {
	self = [self initWithGenerators: generators step: step andRoutine: routine];
	[self setQueue: queue];
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators thread:(SomePromiseThread*) thread andRoutine:(SPRoutine) routine {
	self = [self initWithGenerators: generators andRoutine: routine];
	[self setThread: thread];
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators thread:(SomePromiseThread*) thread delta: (NSTimeInterval) delta andRoutine:(SPRoutine) routine {
	self = [self initWithGenerators: generators delta: delta andRoutine: routine];
	[self setThread: thread];
	return self;
}

- (instancetype) initWithGenerators:(NSArray<SPGenerator*>*) generators thread:(SomePromiseThread*) thread step: (NSInteger) step andRoutine:(SPRoutine) routine {
	self = [self initWithGenerators: generators step: step andRoutine: routine];
	[self setThread: thread];
	return self;
}

- (void) setQueue :(dispatch_queue_t) operationQueue {
	if (self.isCancelled || self.isDone || _inProgress) {
		return;
	}
	_operatioThread = nil;
	_operationQueue = operationQueue;
}

- (void) setThread:(SomePromiseThread*) operationThread {
	if (self.isCancelled || self.isDone || _inProgress) {
		return;
	}
	_operationQueue = nil;
	_operatioThread = operationThread;
}

- (void) cancel {
	self.isCancelled = YES;
}

- (void) run {
	if (self.isCancelled || self.isDone) {
		return;
	}
	_inProgress = YES;

	if (_operationQueue) {
		dispatch_async(_operationQueue, ^{
			[self _run];
		});
	} else {
		[_operatioThread performBlock:^{
			[self _run];
		}];
	}
}

- (NSArray* _Nullable) results {
	if (!self.isDone) {
		return nil;
	}
	return [_routineResults copy];
}


@end

@implementation SPCoRoutine (private)

- (void) _updateIndex {
	if (self.isCancelled || self.isDone) {
		return;
	}

	if (_finishedIterators == _generators.count) {
		self.isDone = YES;
		return;
	}

	if (_index < _generators.count - 1) {
		_index++;
	} else {
		_index = 0;
	}
}

- (void) _run {

	if (_generators[_index].finished) {
		[self _updateIndex];
		[self run];
	}

	SPGenerator    *currentGenerator = _generators[_index].generator;
	SPRoutine	   routine           = _generators[_index].routine;
	NSInteger      step              = _generators[_index].step;
	NSTimeInterval timeInterval      = _generators[_index].timeinterval;

	__block BOOL done = NO;

	if (step > 0) {
		__block int doneItems = 0;
		while (doneItems < step && !done && !self.isCancelled) {
			SPGeneratorResult *result = [currentGenerator next];
			done = result.done;
			if (!done) {
				doneItems++;
				id routineResult = routine(result.value);
				if (routineResult) {
					[self->_routineResults addObject:routineResult];
				}
			}
		}
	} else if (timeInterval > 0) {
		__block NSTimeInterval timePassed = 0;
		NSDate *before = [NSDate date];
		while (timePassed < timeInterval && !done && !self.isCancelled) {
			SPGeneratorResult *result = [currentGenerator next];
			done = result.done;
			if(!done) {
				id routineResult = routine(result.value);
				if (routineResult) {
					[self->_routineResults addObject:routineResult];
				}
				NSDate *after = [NSDate date];
				timePassed = [after timeIntervalSinceDate:before];
			}
		}
	} else {
		while (!done && !self.isCancelled) {
			SPGeneratorResult *result = [currentGenerator next];
			done = result.done;
			if (!done) {
				id routineResult = routine(result.value);
				if (routineResult) {
					[self->_routineResults addObject:routineResult];
				}
			}
		}
	}

	if (done) {
		_generators[_index].finished = YES;
		_finishedIterators++;
	}
	[self _updateIndex];
	[self run];
}

@end
