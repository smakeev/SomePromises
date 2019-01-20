//
//  SomePromiseDataStream.m
//  SomePromises
//
//  Created by Sergey Makeev on 04/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseDataStream.h"
#import "SomePromiseThread.h"
#import "SomePromiseEvents.h"
#import "SomePromiseUtils.h"
#import "SomePromiseExtend.h"
#import "SomePromiseTypes.h"

#import <UIkit/UIkit.h>

SPAction* sp_action(id object, SPActionBlock action)
{
	return [[SPAction alloc] initWithAssociatedObject:object action:action];
}

@class __SPDataStreamKVOSource;
@protocol __SPDataStreamKVOSourceArray <NSObject>
@required
- (void) _removeSource:(__SPDataStreamKVOSource*)source;
- (void) _closeStream;
@end

@interface __SPDataStreamKVOSource : NSObject
{
    __weak id<__SPDataStreamKVOSourceArray> _store;
}
@property (nonatomic, weak, readonly) id source;
@property (nonatomic) BOOL closeOnDestroy;
@property (nonatomic, copy) NSString *keyPath;

@end

@implementation __SPDataStreamKVOSource

- (instancetype) initWithSource:(id)source andStore:(id<__SPDataStreamKVOSourceArray>)store
{
	self = [super init];
	
	if(self)
	{
		_store = store;
		_source = source;
		@sp_avoidblockretain(self)
			[_source spAddDestroyListener:^(NSDictionary *msg) {
				@sp_strongify(self)
				guard(self) else {return;}
				[self->_store _removeSource:self];
				[self closeStreamIfNeeded];
			} message:nil];
		@sp_avoidend(self)
		
	}
	return self;
}

- (void) closeStreamIfNeeded
{
	if(self.closeOnDestroy)
		[_store _closeStream];
}

@end

@interface __SPMergedDataStream : SPDataStream
{
	NSArray<SPDataStream*> *_streams;
	SPMergeRule _mergeRule;
}

@end

@implementation __SPMergedDataStream

- (instancetype) initWithMergeRule:(SPMergeRule)mergeRule streams:(NSArray*)streams
{
	self = [super initWithTimes:0];
	if(self)
	{
		_mergeRule = [mergeRule copy];
		_streams = [streams copy];
		for (SPDataStream *stream in _streams)
		{
			[stream then:self];
		}
	}
	return self;
}

- (void) internalDoNext:(id) value
{
	id mergedValue = value;
	SPArray *array = [SPArray new];
	BOOL hasNils = NO;
	for(SPDataStream *stream in _streams)
	{
		id lastResult = stream.lastResult;
		if(lastResult == nil)
		{
			hasNils = YES;
			if([self incomingNilIgnorring])
			{
				break;
			}
		}
		[array add:lastResult];
	}
	if([self incomingNilIgnorring] && hasNils)
	{
		return;
	}
	mergedValue = _mergeRule(array);
	[self doNext:mergedValue];
}

- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value
{
	[self internalDoNext:value];
}

@end

@interface SPDataStream () <__SPDataStreamKVOSourceArray, SPDataStreamObserver>
{
	dispatch_queue_t _syncQueue;
	SomeClassBox *_lastResult;
	NSError *_error;
	BOOL _completed;
	NSMutableArray *_onComplete;
	NSMutableArray *_onError;
	NSMutableArray<FilterBlock> *_filters;
	NSMutableArray<MapBlock> *_maps;
	
	dispatch_queue_t _queue;
	SomePromiseThread *_thread;
	
	NSPointerArray *_observers;
	NSMutableArray *_collected;
	SPArray *_collectedSP;
	
	BOOL _ignoreCommingNil;
	
	//KVO:
	NSMutableArray<__SPDataStreamKVOSource*> *_kvoSources;
	
	NSMutableSet<NSNotificationCenter*> *_notificationCenters;
	
	NSArray<SPDataStream*> *_gluedStreams;
	
	NSInteger _times;
	BOOL _unlimited;
}

//private methods.
- (BOOL) filter:(id)value;
- (id) map:(id)value;

- (instancetype) init NS_DESIGNATED_INITIALIZER;

@end

@implementation SPDataStream
@synthesize delegate = _delegate;
@synthesize error = _error;
@synthesize completed = _completed;
@synthesize lastResult;

- (instancetype) init
{	self = [super init];
	return nil;
}

- (id) lastResult
{
	__block id result = nil;
	dispatch_sync(_syncQueue, ^{
		result = self->_lastResult.value;
	});
	return result;
}

- (NSError*) error
{
	__block NSError *result = nil;
	dispatch_sync(_syncQueue, ^{
		result = self->_error;
	});
	return result;
}

- (BOOL) completed
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		result = self->_completed;
	});
	return result;
}

- (id<SPDataStreamDelegate>) delegate
{
  __block id<SPDataStreamDelegate> delegate = nil;
  dispatch_sync(_syncQueue, ^{
  		delegate = self->_delegate;
  });
  return delegate;
}

- (void) setDelegate:(id<SPDataStreamDelegate>)delegate
{
  dispatch_sync(_syncQueue, ^{
  	self->_delegate = delegate;
  });
}

+ (instancetype) new
{
	return [[SPDataStream alloc] initWithTimes:0];
}

+ (instancetype) newOnThread:(SomePromiseThread*)thread times:(NSInteger) times
{
	return [[SPDataStream alloc] initWithThread:thread times:times];
}

+ (instancetype) newOnQueue:(dispatch_queue_t) queue times:(NSInteger) times
{
	return [[SPDataStream alloc] initWithQueue:queue times:times];
}

+ (instancetype) newWithSource:(id)source keyPath:(NSString*)keyPath times:(NSInteger) times
{
	return [[SPDataStream alloc] initWithSource:source keyPath:keyPath times:times];
}

+ (instancetype) newWithSource:(id)source keyPath:(NSString*)keyPath queue:(dispatch_queue_t _Nonnull)queue times:(NSInteger) times
{
	return [[SPDataStream alloc] initWithSource:source keyPath:keyPath queue:queue times:times];
}

+ (instancetype) newWithSource:(id)source keyPath:(NSString*)keyPath thread:(SomePromiseThread *_Nonnull)thread times:(NSInteger) times
{
	return [[SPDataStream alloc] initWithSource:source keyPath:keyPath thread:thread times:times];
}

- (instancetype) initWithTimes:(NSInteger)times
{
	self = [super init];
	if(self)
	{
		_times = times;
		if(_times == 0)
		{
			_unlimited = YES;
		}
		else
		{
			_unlimited = NO;
		}
		_syncQueue = dispatch_queue_create("SomePromisesDataSreamSynchronize", DISPATCH_QUEUE_SERIAL);
		_lastResult = [SomeClassBox empty];
		_error = nil;
		_completed = NO;
		_onComplete = [NSMutableArray new];
		_onError = [NSMutableArray new];
		_filters = [NSMutableArray new];
		_maps = [NSMutableArray new];
		_observers = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsWeakMemory];
		_ignoreCommingNil = NO;
		_kvoSources = [NSMutableArray new];
		_notificationCenters = [NSMutableSet new];
	}
	return self;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue times:(NSInteger)times
{
   self = [self initWithTimes:times];
   if(self)
   {
      _queue = queue;
   }
   return self;
}

- (instancetype)initWithThread:(SomePromiseThread*)thread times:(NSInteger)times
{
   self = [self initWithTimes:times];
   if(self)
   {
		_thread = thread;
   }
   return self;
}

- (instancetype)initWithSource:(id)source keyPath:(NSString*)keyPath times:(NSInteger)times
{
	self = [self initWithTimes:times];
	if(self)
	{
		[self addSource:source keyPath:keyPath closeOnDestroy:YES];
	}
	return self;
}

- (instancetype)initWithSource:(id)source keyPath:(NSString*)keyPath queue:(dispatch_queue_t _Nonnull)queue times:(NSInteger)times
{
	self = [self initWithTimes:times];
	if(self)
	{
		_queue = queue;
		[self addSource:source keyPath:keyPath closeOnDestroy:YES];
	}
	return self;
}

- (instancetype)initWithSource:(id)source keyPath:(NSString*)keyPath thread:(SomePromiseThread *_Nonnull)thread times:(NSInteger)times
{
	self = [self initWithTimes:times];
	if(self)
	{
		_thread = thread;
		[self addSource:source keyPath:keyPath closeOnDestroy:YES];
	}
	return self;
}

- (dispatch_queue_t _Nullable) queue
{
	__block dispatch_queue_t queue;
	dispatch_sync(_syncQueue, ^{
		queue = self->_queue;
	});
	return queue;
}

- (SomePromiseThread *_Nullable) thread
{
	__block SomePromiseThread *thread;
	dispatch_sync(_syncQueue, ^{
		thread = self->_thread;
	});
	return thread;
}

- (void) setThread:(SomePromiseThread *_Nonnull)thread
{
	dispatch_sync(_syncQueue, ^{
		self->_thread = thread;
		self->_queue = nil;
	});
}

- (void) setQueue:(dispatch_queue_t _Nullable)queue
{
	dispatch_sync(_syncQueue, ^{
		self->_thread = nil;
		self->_queue = queue;
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(SomePromiseThread *_Nonnull))onThread
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(SomePromiseThread *thread){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf setThread:thread];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(dispatch_queue_t _Nonnull))onQueue
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(dispatch_queue_t queue){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf setQueue:queue];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (BOOL) incomingNilIgnorring
{
	__block BOOL ignoringNulls = NO;
	dispatch_sync(_syncQueue, ^{
		ignoringNulls = self->_ignoreCommingNil;
	});
	return ignoringNulls;
}

- (void) ignoreIncomingNil:(BOOL)yesNo
{
	dispatch_sync(_syncQueue, ^{
		self->_ignoreCommingNil = yesNo;
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(BOOL))ignoreIncomingNil
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(BOOL ignore){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf ignoreIncomingNil:ignore];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (void) addObserver:(id<SPDataStreamObserver>)observer
{
	dispatch_sync(_syncQueue, ^{
		[self->_observers compact];
		for(int i = 0; i < self->_observers.count; ++i)
		{
			if([self->_observers pointerAtIndex:i] == &observer)
			{
				return;
			}
		}
		[self->_observers addPointer:(__bridge void * _Nullable)(observer)];
	});
}

- (void) removeObserver:(id<SPDataStreamObserver>)observer
{
	guard(observer) else return;
	dispatch_sync(_syncQueue, ^{
		int foundIndex = -1;
		for(int i = 0; i < self->_observers.count; ++i)
		{
			id current = [self->_observers pointerAtIndex:i];
			if(current && current == observer)
			{
				foundIndex = i;
				break;
			}
		}
		guard(foundIndex >= 0) else return;
		[self->_observers removePointerAtIndex:foundIndex];
		[self->_observers compact];
	});
}

- (void) removeObservers
{
	_observers = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsWeakMemory];
}


- (SPDataStream *_Nonnull(^ __nonnull)(id<SPDataStreamObserver>))addObserver
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(id<SPDataStreamObserver> observer){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf addObserver:observer];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(id<SPDataStreamObserver>))removeObserver
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(id<SPDataStreamObserver> observer){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf removeObserver:observer];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(void))skipObservers
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf removeObservers];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (void) skip
{
	dispatch_sync(_syncQueue, ^{
		guard(!self->_completed) else {return;}
		[self->_lastResult skip];
	});
}

- (void) skipFilter
{
	dispatch_sync(_syncQueue, ^{
		[self->_filters removeAllObjects];
	});
}

- (void) skipMap
{
	dispatch_sync(_syncQueue, ^{
		[self->_maps removeAllObjects];
	});
}

- (void) addFilter:(FilterBlock)filter
{
	dispatch_sync(_syncQueue, ^{
		[self->_filters addObject:[filter copy]];
	});
}

- (void) addMap:(MapBlock)map
{
	dispatch_sync(_syncQueue, ^{
		[self->_maps addObject:[map copy]];
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(FilterBlock))filter
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(FilterBlock filter){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf addFilter:filter];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(MapBlock))map
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(MapBlock map){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf addMap:map];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (void) bind:(id)target listener:(SPListener)listener
{
	__block id result;
	dispatch_sync(_syncQueue, ^{
		[self->_lastResult bindNext:target listener:listener];
		result = self->_lastResult.value;
	});
	
	if(_queue)
	{
		dispatch_async(_queue, ^{
			listener(result);
		});
	}
	else if(_thread)
	{
		[_thread performBlock:^{
			listener(result);
		}];
	}
	else
	{
		listener(result);
	}
}

- (void) bindNext:(id)target listener:(SPListener)listener
{
		dispatch_sync(_syncQueue, ^{
			[self->_lastResult bindNext:target listener:listener];
		});
}

- (void) bindOnce:(id)target listener:(SPListener)listener
{
		dispatch_sync(_syncQueue, ^{
			[self->_lastResult bindOnce:target listener:listener];
		});
}

- (void) unbind:(id)target
{
		dispatch_sync(_syncQueue, ^{
			[self->_lastResult unbind:target];
		});
}

- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull, SPListener _Nullable))bind
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(id target, SPListener listener){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf bind:target listener:listener];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull, SPListener _Nullable))bindNext
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(id target, SPListener listener){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf bindNext:target listener:listener];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull, SPListener _Nullable))bindOnce
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(id target, SPListener listener){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf bindOnce:target listener:listener];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull))unbind
{
    __weak SPDataStream *weakSelf = self;
	return [^SPDataStream *(id target, SPListener listener){
			__strong SPDataStream *strongSelf = weakSelf;
			if(strongSelf)
			{
				[strongSelf unbind:target];
				return strongSelf;
			}
			return nil;
	} copy];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	dispatch_sync(_syncQueue, ^{
		for(__SPDataStreamKVOSource *current in self->_kvoSources)
		{
			[current.source removeObserver:self forKeyPath:current.keyPath];
		}
		
		for(NSNotificationCenter *center in self->_notificationCenters.allObjects)
		{
			[center removeObserver:self];
		}
	});
}

- (id) take
{
	__block id result = nil;
	dispatch_sync(_syncQueue, ^{
		guard(!self->_completed) else {return;}
		result = self->_lastResult.value;
	});
	return result;
}

- (void) addOnErrorHandler:(OnSPStreamErrorHandler)handler
{
	dispatch_sync(_syncQueue, ^{
		[self->_onComplete addObject:[handler copy]];
	});
}

- (void) addOnCompleteHandler:(OnSPStreamCompletedHandler)handler
{
	dispatch_sync(_syncQueue, ^{
		[self->_onError addObject:[handler copy]];
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(OnSPStreamErrorHandler))onError
{
	__weak SPDataStream *weakSelf = self;
	return [^SPDataStream*(OnSPStreamErrorHandler handler){
		__strong SPDataStream *strongSelf = weakSelf;
		guard(strongSelf) else {return nil;}
		[strongSelf addOnErrorHandler:handler];
		return strongSelf;
	} copy];
}

- (SPDataStream *_Nonnull(^ __nonnull)(OnSPStreamCompletedHandler))onComplete
{
	__weak SPDataStream *weakSelf = self;
	return [^SPDataStream*(OnSPStreamCompletedHandler handler){
		__strong SPDataStream *strongSelf = weakSelf;
		guard(strongSelf) else {return nil;}
		[strongSelf addOnCompleteHandler:handler];
		return strongSelf;
	} copy];
}

- (void) skipCompleteHandlers
{
	dispatch_sync(_syncQueue, ^{
		[self->_onComplete removeAllObjects];
	});
}

- (void) skipErrorHandlers
{
	dispatch_sync(_syncQueue, ^{
		[self->_onError removeAllObjects];
	});
}

- (void) skipHandlers
{
   [self skipErrorHandlers];
   [self skipCompleteHandlers];
}

- (void) unbindAll
{
	dispatch_sync(_syncQueue, ^{
		[self->_lastResult unbindAll];
	});
}

static void getObservers(NSMutableArray *target, NSPointerArray *source)
{
	for (id<SPDataStreamObserver> observer in source)
	{
		[target addObject:observer];
	}
}

- (void) doNext:(id)value
{
	guard(![self completed]) else {return;}
    __block id<SPDataStreamDelegate> delegate = nil;
    __block NSMutableArray<id<SPDataStreamObserver> > *observers = [NSMutableArray new];
	__block BOOL hasChanged = NO;
	__block BOOL shouldComplete = NO;
	__block id newValue = nil;
	dispatch_sync(_syncQueue, ^{
	    // check filters.
	    delegate = self->_delegate;
	    getObservers(observers, self->_observers);
	    if(![self filter:value])
	    {
	       return;
		}
		hasChanged = YES;
		newValue = [self map:value];
		[self->_collectedSP add:newValue];
		if(newValue || !self->_ignoreCommingNil)
		{
			[self->_lastResult skipValue:newValue]; //We don't want to call subscribers in sync queue;
			if(!self->_unlimited)
			{
				self->_times -= 1;
				if(self->_times == 0)
				{
					shouldComplete = YES;
				}
			}
		}
		if(newValue)
		{
			[self->_collected addObject:newValue];
		}
	});
	if(![self completed])
	{ //now call subscribers;
		if(_queue)
		{
			__weak SPDataStream *weakSelf = self;
			dispatch_async(_queue, ^{
				__strong SPDataStream *strongSelf = weakSelf;
				guard(strongSelf) else {return;}
				for (id<SPDataStreamObserver> observer in observers)
				{
					if([observer respondsToSelector:@selector(stream:hasIncomingData:)])
					{
						[observer stream:strongSelf hasIncomingData:value];
					}
				}
				
				if(delegate && [delegate respondsToSelector:@selector(stream:hasIncomingData:)])
				{
					[delegate stream:strongSelf hasIncomingData:value];
				}
				
				if(hasChanged)
				{
					[strongSelf->_lastResult callListenersForward];
				
					if(delegate && [delegate respondsToSelector:@selector(stream:willUpdatedWith:)])
					{
						[delegate stream:strongSelf willUpdatedWith:value];
					}
				
					if(delegate && [delegate respondsToSelector:@selector(stream:hasUpdatedTo:)])
					{
						[delegate stream:strongSelf hasUpdatedTo:newValue];
					}
					
					for (id<SPDataStreamObserver> observer in observers)
					{
						if([observer respondsToSelector:@selector(stream:willUpdatedWith:)])
						{
							[observer stream:strongSelf willUpdatedWith:value];
						}
				
						if([observer respondsToSelector:@selector(stream:hasUpdatedTo:)])
						{
							[observer stream:strongSelf hasUpdatedTo:newValue];
						}
					}
				}
				
				if(shouldComplete)
				{
					[strongSelf doComplete];
				}
			});
		}
		else if(_thread)
		{
			__weak SPDataStream *weakSelf = self;
			[_thread performBlock:^{
				__strong SPDataStream *strongSelf = weakSelf;
				guard(strongSelf) else {return;}
				
				for (id<SPDataStreamObserver> observer in observers)
				{
					if([observer respondsToSelector:@selector(stream:hasIncomingData:)])
					{
						[observer stream:strongSelf hasIncomingData:value];
					}
				}
				
				if(delegate && [delegate respondsToSelector:@selector(stream:hasIncomingData:)])
				{
					[delegate stream:strongSelf hasIncomingData:value];
				}
				
				if(hasChanged)
				{
					[strongSelf->_lastResult callListenersForward];
				
					if(delegate && [delegate respondsToSelector:@selector(stream:willUpdatedWith:)])
					{
						[delegate stream:strongSelf willUpdatedWith:value];
					}
				
					if(delegate && [delegate respondsToSelector:@selector(stream:hasUpdatedTo:)])
					{
						[delegate stream:strongSelf hasUpdatedTo:newValue];
					}
					
					for (id<SPDataStreamObserver> observer in observers)
					{
						if([observer respondsToSelector:@selector(stream:willUpdatedWith:)])
						{
							[observer stream:strongSelf willUpdatedWith:value];
						}
				
						if([observer respondsToSelector:@selector(stream:hasUpdatedTo:)])
						{
							[observer stream:strongSelf hasUpdatedTo:newValue];
						}
					}
				}
				
				if(shouldComplete)
				{
					[strongSelf doComplete];
				}

			}];
		}
		else
		{
			for (id<SPDataStreamObserver> observer in observers)
			{
				if([observer respondsToSelector:@selector(stream:hasIncomingData:)])
				{
					[observer stream:self hasIncomingData:value];
				}
			}

		
			if(delegate && [delegate respondsToSelector:@selector(stream:hasIncomingData:)])
			{
				[delegate stream:self hasIncomingData:value];
			}
			
			
			if(hasChanged)
			{
				[_lastResult callListenersForward];
				if(delegate && [delegate respondsToSelector:@selector(stream:willUpdatedWith:)])
				{
					[delegate stream:self willUpdatedWith:value];
				}
				if(delegate && [delegate respondsToSelector:@selector(stream:hasUpdatedTo:)])
				{
					[delegate stream:self hasUpdatedTo:newValue];
				}
				
				for (id<SPDataStreamObserver> observer in observers)
				{
					if([observer respondsToSelector:@selector(stream:willUpdatedWith:)])
					{
						[observer stream:self willUpdatedWith:value];
					}
				
					if([observer respondsToSelector:@selector(stream:hasUpdatedTo:)])
					{
						[observer stream:self hasUpdatedTo:newValue];
					}
				}
				
				if(shouldComplete)
				{
					[self doComplete];
				}
			}
		}
	}
}

- (void) doError:(NSError*)error
{
	guard(![self completed] && ![self error]) else {return;}
	__block id<SPDataStreamDelegate> delegate = nil;
	__block NSMutableArray<id<SPDataStreamObserver> > *observers = [NSMutableArray new];
	__block NSArray<OnSPStreamErrorHandler> *handlers;
	dispatch_sync(_syncQueue, ^{
	    self->_error = error;
	    delegate = self->_delegate;
	    getObservers(observers, self->_observers);
		handlers = [self->_onError copy];
	});
	[self doComplete];
	
	if(_queue)
	{
		__weak SPDataStream *weakSelf = self;
		dispatch_async(_queue, ^{
			__strong SPDataStream *strongSelf = weakSelf;
			for(OnSPStreamErrorHandler handler in handlers)
			{
				handler(strongSelf, error);
			}
			
			if(delegate && [delegate respondsToSelector:@selector(stream:gotError:)])
			{
				[delegate stream:strongSelf gotError:error];
			}
			
			for (id<SPDataStreamObserver> observer in observers)
			{
				if([observer respondsToSelector:@selector(stream:gotError:)])
				{
					[observer stream:strongSelf gotError:error];
				}
			}
		});
	}
	else if(_thread)
	{
		__weak SPDataStream *weakSelf = self;
		[_thread performBlock:^{
			__strong SPDataStream *strongSelf = weakSelf;
			for(OnSPStreamErrorHandler handler in handlers)
			{
				handler(strongSelf, error);
			}
			if(delegate && [delegate respondsToSelector:@selector(stream:gotError:)])
			{
				[delegate stream:strongSelf gotError:error];
			}
			
			for (id<SPDataStreamObserver> observer in observers)
			{
				if([observer respondsToSelector:@selector(stream:gotError:)])
				{
					[observer stream:strongSelf gotError:error];
				}
			}
		}];
	}
	else
	{
		for(OnSPStreamErrorHandler handler in handlers)
		{
			handler(self, error);
		}
		if(delegate && [delegate respondsToSelector:@selector(stream:gotError:)])
		{
			[delegate stream:self gotError:error];
		}
		
		for (id<SPDataStreamObserver> observer in observers)
		{
			if([observer respondsToSelector:@selector(stream:gotError:)])
			{
				[observer stream:self gotError:error];
			}
		}
	}
}

- (void) doComplete
{
   guard(![self completed]) else {return;}
	__block id<SPDataStreamDelegate> delegate = nil;
 	__block NSMutableArray<id<SPDataStreamObserver> > *observers = [NSMutableArray new];
	__block NSArray<OnSPStreamCompletedHandler> *handlers;
	dispatch_sync(_syncQueue, ^{
		handlers = [self->_onComplete copy];
		delegate = self->_delegate;
		getObservers(observers, self->_observers);
		self->_completed = YES;
	});
	if(_queue)
	{
		__weak SPDataStream *weakSelf = self;
		dispatch_async(_queue, ^{
			__strong SPDataStream *strongSelf = weakSelf;
			for(OnSPStreamCompletedHandler handler in handlers)
			{
				handler(strongSelf);
			}
			if(delegate && [delegate respondsToSelector:@selector(streamCompleted:)])
			{
				[delegate streamCompleted:strongSelf];
			}

			for (id<SPDataStreamObserver> observer in observers)
			{
				[observer streamCompleted:strongSelf];
			}
		});
	}
	else if(_thread)
	{
		__weak SPDataStream *weakSelf = self;
		[_thread performBlock:^{
			__strong SPDataStream *strongSelf = weakSelf;
			for(OnSPStreamCompletedHandler handler in handlers)
			{
				handler(strongSelf);
			}
			if(delegate && [delegate respondsToSelector:@selector(streamCompleted:)])
			{
				[delegate streamCompleted:strongSelf];
			}
			
			for (id<SPDataStreamObserver> observer in observers)
			{
				[observer streamCompleted:strongSelf];
			}

		}];
	}
	else
	{
		for(OnSPStreamCompletedHandler handler in handlers)
		{
			handler(self);
		}
		
		if(delegate && [delegate respondsToSelector:@selector(streamCompleted:)])
		{
			[delegate streamCompleted:self];
		}
		
		for (id<SPDataStreamObserver> observer in observers)
		{
			[observer streamCompleted:self];
		}

	}
}

- (void) fromArray:(NSArray*)array
{
	for(id element in array)
	{
		[self doNext:element];
	}
}

- (void) fromSPArray:(SPArray*)array
{
	for(SPArrayElementWrapper *element in _collectedSP)
	{
		[self doNext:element.value];
	}
}

- (void) collectToArray:(BOOL)onOff
{
	dispatch_sync(_syncQueue, ^{
		if(onOff)
		{
			if(self->_collected) {return;}
			self->_collected = [NSMutableArray new];
		}
		else
		{
			self->_collected = nil;
		}
	});
}

- (void) collectToSPArray:(BOOL)onOff
{
	dispatch_sync(_syncQueue, ^{
		if(onOff)
		{
			if(self->_collectedSP) {return;}
			self->_collectedSP = [SPArray new];
		}
		else
		{
			self->_collectedSP = nil;
		}
	});
}

- (NSArray *_Nullable) collectedArray
{
	__block NSArray *returnArray = nil;
	dispatch_sync(_syncQueue, ^{
		returnArray = [self->_collected copy];
	});
	return returnArray;
}

- (SPArray *_Nullable) collectedSPArray
{
	__block SPArray *returnArray = nil;
	dispatch_sync(_syncQueue, ^{
		returnArray = [self->_collectedSP copy];
	});
	return returnArray;
}

- (void) addSource:(id)source keyPath:(NSString*)keyPath closeOnDestroy:(BOOL)yesNo
{
	__block __SPDataStreamKVOSource *sourceWrapper = nil;
	dispatch_sync(_syncQueue, ^{
		//search for source wrapper
		for(__SPDataStreamKVOSource *current in self->_kvoSources)
		{
			if (current.source == source && [current.keyPath isEqualToString:keyPath])
			{
				sourceWrapper = current;
				return;
			}
		}
	});
	
	BOOL needToAdd = NO;
	if(!sourceWrapper)
	{
		sourceWrapper = [[__SPDataStreamKVOSource alloc] initWithSource:source andStore:self];
		sourceWrapper.keyPath = keyPath;
		needToAdd = YES;
	}

	sourceWrapper.closeOnDestroy = yesNo;
	
	[source addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
	
	if(needToAdd)
	{
		dispatch_sync(_syncQueue, ^{
			[self->_kvoSources addObject:sourceWrapper];
		});
	}
}

- (void) removeSource:(id)source
{
	NSMutableArray *wrappers = [NSMutableArray new];
	dispatch_sync(_syncQueue, ^{
		//search for source wrapper
		for(__SPDataStreamKVOSource *current in self->_kvoSources)
		{
			if (current.source == source)
			{
				[wrappers addObject:current];
			}
		}
	});

	if(wrappers.count)
	{
		for(__SPDataStreamKVOSource *current in wrappers)
			[self _removeSource:current];
	}
}

- (void) removeAllSources
{
	dispatch_sync(_syncQueue, ^{
		[self->_kvoSources removeAllObjects];
	});
}

#if (TARGET_OS_IOS)

- (void) addTextField:(UITextField*)textField
{
	[[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(textUpdated:)
        name: UITextFieldTextDidChangeNotification
        object:textField];
	[self addSource:textField keyPath:@"text" closeOnDestroy:NO];
}

- (void) removeTextField:(UITextField*)textField
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:textField];
	[self removeSource:textField];
}

- (void) removeAllTextFields
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
	
	//search for text fields in sources
	NSMutableArray *_sourcesToBeDeleted = [NSMutableArray new];
	dispatch_sync(_syncQueue, ^{
		for(NSObject *source in self->_kvoSources)
		{
			if([source isKindOfClass:[UITextField class]])
			{
				[_sourcesToBeDeleted addObject:source];
			}
		}
		
		[self->_kvoSources removeObjectsInArray:_sourcesToBeDeleted];
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(UITextField *_Nonnull))addTextField
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(UITextField *) = ^SPDataStream*(UITextField *text)
   	{
      @sp_strongify(self)
      [self addTextField:text];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (void) addTextView:(UITextView*)textView
{
	[[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(textUpdated:)
        name: UITextViewTextDidChangeNotification
        object:textView];
	[self addSource:textView keyPath:@"text" closeOnDestroy:NO];
}

- (void) removeTextView:(UITextView*)textView
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:textView];
	[self removeSource:textView];
}

- (void) removeAllTextViews
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
	
	//search for text views in sources
	NSMutableArray *_sourcesToBeDeleted = [NSMutableArray new];
	dispatch_sync(_syncQueue, ^{
		for(NSObject *source in self->_kvoSources)
		{
			if([source isKindOfClass:[UITextView class]])
			{
				[_sourcesToBeDeleted addObject:source];
			}
		}
		
		[self->_kvoSources removeObjectsInArray:_sourcesToBeDeleted];
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(UITextView *_Nonnull))addTextView
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(UITextView *) = ^SPDataStream*(UITextView *text)
   	{
      @sp_strongify(self)
      [self addTextView:text];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (void) addSwitch:(UISwitch*)switchView
{
	if(@available(iOS 11, *)) {
		[self addSource:switchView keyPath:@"on" closeOnDestroy:NO];
		[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
	}
}

- (void) removeSwitch:(UISwitch*)switchView
{
	[self removeSource:switchView];
	[switchView removeTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void) removeAllSwitches
{
	NSMutableArray *_sourcesToBeDeleted = [NSMutableArray new];
	dispatch_sync(_syncQueue, ^{
		for(NSObject *source in self->_kvoSources)
		{
			if([source isKindOfClass:[UISwitch class]])
			{
				[_sourcesToBeDeleted addObject:source];
				[((UISwitch*)source) removeTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
			}
		}
		[self->_kvoSources removeObjectsInArray:_sourcesToBeDeleted];
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(UISwitch *_Nonnull))addSwitch
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(UISwitch *) = ^SPDataStream*(UISwitch *switchView)
   	{
      @sp_strongify(self)
      [self addSwitch:switchView];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (void) addControl:(UIControl*)control forEvent:(UIControlEvents)event
{
	[control addTarget:self action:@selector(controlAction:) forControlEvents:event];
}

- (void) removeControl:(UIControl*)control forEvent:(UIControlEvents)event
{
	[control removeTarget:self action:@selector(controlAction:) forControlEvents:event];
}

- (void) removeAllControlsForEvent:(UIControlEvents)event
{
	dispatch_sync(_syncQueue, ^{
		for(NSObject *source in self->_kvoSources)
		{
			if([source isKindOfClass:[UISwitch class]])
			{
				[((UIControl*)source) removeTarget:self action:@selector(controlAction:) forControlEvents:event];
			}
		}
	});
}

- (SPDataStream *_Nonnull(^ __nonnull)(UIControl *_Nonnull, UIControlEvents))addControl
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(UIControl *, UIControlEvents) = ^SPDataStream*(UIControl *control, UIControlEvents events)
   	{
      @sp_strongify(self)
      [self addControl:control forEvent:events];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

#endif

- (void) addNSNotification:(NSString*_Nonnull)notificationName
{
	@sp_avoidblockretain(self)
		[[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:nil usingBlock:^(NSNotification *note) {
			@sp_strongify(self)
			guard(self) else {return;}
			[self doNext:note];
		}];
	@sp_avoidend(self)
}

- (void) addNSNotification:(NSString*_Nonnull)notificationName
	fromNotificationCenter:(NSNotificationCenter*_Nullable)center
{
	if(center)
	{
		dispatch_sync(_syncQueue, ^{
			[self->_notificationCenters addObject:center];
		});
	}
	else
	{
		center = [NSNotificationCenter defaultCenter];
	}

	@sp_avoidblockretain(self)
		[center addObserverForName:notificationName object:nil queue:nil usingBlock:^(NSNotification *note) {
			@sp_strongify(self)
			guard(self) else {return;}
			[self doNext:note];
		}];
	@sp_avoidend(self)
}

- (void) addNSNotification:(NSString*_Nonnull)notificationName
				fromObject:(id _Nullable)object
{

	@sp_avoidblockretain(self)
		[[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:object queue:nil usingBlock:^(NSNotification *note) {
			@sp_strongify(self)
			guard(self) else {return;}
			[self doNext:note];
		}];
	@sp_avoidend(self)
}

- (void) addNSNotification:(NSString*_Nonnull)notificationName
				fromObject:(id _Nullable)object
	fromNotificationCenter:(NSNotificationCenter*_Nullable)center
{
	if(center)
	{
		dispatch_sync(_syncQueue, ^{
			[self->_notificationCenters addObject:center];
		});
	}
	else
	{
		center = [NSNotificationCenter defaultCenter];
	}
	@sp_avoidblockretain(self)
		[center addObserverForName:notificationName object:object queue:nil usingBlock:^(NSNotification *note) {
			@sp_strongify(self)
			guard(self) else {return;}
			[self doNext:note];
		}];
	@sp_avoidend(self)

}

- (void) removeAllNSNotificationsForNotificationCenter:(NSNotificationCenter*_Nullable)center
{
	if(center == nil)
	{
		center = [NSNotificationCenter	defaultCenter];
	}
	[center removeObserver:self];
}

- (void) removeAllNSNotificationsForObject:(id _Nullable)object
					fromNotificationCenter:(NSNotificationCenter*_Nullable)center
{
	if(center == nil)
	{
		center = [NSNotificationCenter	defaultCenter];
	}
	[center removeObserver:self name:nil object:object];
}

- (void) removeNSNotification:(NSString*_Nonnull)notificationName
	   fromNotificationCenter:(NSNotificationCenter*_Nullable)center
{
	if(center == nil)
	{
		center = [NSNotificationCenter	defaultCenter];
	}
	[center removeObserver:self name:notificationName object:nil];
}

- (void) removeNSNotification:(NSString *)notificationName
					forObject:(id _Nullable)object
	   fromNotificationCenter:(NSNotificationCenter*_Nullable)center
{
	if(center == nil)
	{
		center = [NSNotificationCenter	defaultCenter];
	}
	[center removeObserver:self name:notificationName object:object];
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull))addNSNotification
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString*) = ^SPDataStream*(NSString *notName)
   	{
      @sp_strongify(self)
      [self addNSNotification:notName];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, NSNotificationCenter*_Nullable))addNSNotificationFromCenter
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString*, NSNotificationCenter*) = ^SPDataStream*(NSString *notName, NSNotificationCenter *notCenter)
   	{
      @sp_strongify(self)
      [self addNSNotification:notName fromNotificationCenter:notCenter];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nullable))addNSNotificationFromObject
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString*, id) = ^SPDataStream*(NSString *notName, id object)
   	{
      @sp_strongify(self)
      [self addNSNotification:notName fromObject:object];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nullable, NSNotificationCenter *_Nullable))addNSNotificationFromObjectAndCenter
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString*, id, NSNotificationCenter*) = ^SPDataStream*(NSString *notName, id object, NSNotificationCenter *notCenter)
   	{
      @sp_strongify(self)
      [self addNSNotification:notName fromObject:object fromNotificationCenter:notCenter];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (void) addEvent:(NSString*_Nonnull)event fromObject:(id _Nonnull)object
{
	@sp_avoidblockretain(self)
		[(NSObject*)object spOn:event target:self listener:^(NSDictionary * message) {
			@sp_strongify(self)
      		guard(self) else return;
      		[self doNext:message];
		}];
	@sp_avoidend(self)
}

- (void) removeEvent:(NSString*_Nonnull)event fromObject:(id _Nonnull)object
{
	[(NSObject*)object spOff:event target:self];
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nonnull))addEvent
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString*, id) = ^SPDataStream*(NSString *event, id object)
   	{
      @sp_strongify(self)
      guard(self) else return nil;
      [self addEvent:event fromObject:object];
      return self;
	};
   return [block copy];
   @sp_avoidend(self)
}

- (void) addExtend:(NSString*_Nonnull)extendName ofObject:(id _Nonnull)object
{
	@sp_avoidblockretain(self)
		[(NSObject*)object bindTo:extendName listener:self listenerBlock:^(id value){
			@sp_strongify(self)
      		guard(self) else return;
      		[self doNext:value];
		}];
	@sp_avoidend(self)
}

- (void) removeExtend:(NSString*_Nonnull)extendName ofObject:(id _Nonnull)object
{
	[(NSObject*)object unbindFrom:extendName listener:self];
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nonnull))addExtend
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString*, id) = ^SPDataStream*(NSString *event, id object)
   	{
      @sp_strongify(self)
      guard(self) else return nil;
      [self addExtend:event ofObject:object];
      return self;
	};
	return [block copy];
	@sp_avoidend(self)
}

- (void) then:(SPDataStream*)thenStream
{
	[self addObserver:thenStream];
}

- (void) follow:(SPDataStream*)followStream
{
	[followStream addObserver:self];
}

- (SPDataStream *_Nonnull(^ __nonnull)(SPDataStream *_Nonnull))then
{
	@sp_avoidblockretain(self)
		return [^(SPDataStream *thenStream){
			@sp_strongify(self)
			[self then:thenStream];
			return thenStream;
		} copy];
	@sp_avoidend(self)
}

- (SPDataStream *_Nonnull(^ __nonnull)(SPDataStream *_Nonnull))follow
{
	@sp_avoidblockretain(self)
		return [^(SPDataStream *followStream){
			@sp_strongify(self)
			[self follow:followStream];
			return self;
		} copy];
	@sp_avoidend(self)
}

+ (instancetype)glue:(NSArray<SPDataStream*>*)streams
{
	SPDataStream *result = [SPDataStream new];
	result->_gluedStreams = [streams copy];
	for (SPDataStream *stream in streams)
	{
		[stream then:result];
	}
	
	return result;
}

+ (instancetype)concat:(NSArray<SPDataStream*>*)streams
{
	guard(streams.count) else return nil;
	SPDataStream *result = [SPDataStream new];
	[result follow:streams.lastObject];
	guard(streams.count > 1) else return result;
	for (int i = 1; i < streams.count; ++i)
	{
		[streams[i] follow:streams[i-1]];
	}
	
	return result;
}

+ (instancetype)merge:(NSArray<SPDataStream*>*)streams withMergeRule:(SPMergeRule)mergeRule
{
	return [[__SPMergedDataStream alloc] initWithMergeRule:mergeRule streams:streams];
}

//private
#pragma mark -
#pragma mark Private Methods

- (BOOL) filter:(id)value
{
	for (FilterBlock filter in _filters)
	{
		guard(filter(value)) else {return NO;}
	}
	return YES;
}

- (id) map:(id)value
{
    id result = value;
	for(MapBlock map in _maps)
	{
		result = map(result);
	}
	return result;
}

//KVO:
#if (TARGET_OS_IOS)
- (void) textUpdated:(NSNotification*) notification
{
	[self doNext:((UITextField*)notification.object).text];
}

- (void) switchChanged:(UISwitch*)switchView
{
	[self doNext:@(switchView.isOn)];
}

- (void) controlAction:(UIControl*) control
{
	[self doNext:control];
}

#endif

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	[self doNext:change[@"new"]];
}

#pragma mark -
#pragma mark __SPDataStreamKVOSourceArray

- (void) _removeSource:(__SPDataStreamKVOSource*)source
{
	[source.source removeObserver:self forKeyPath:source.keyPath];
	dispatch_sync(_syncQueue, ^{
		[self->_kvoSources removeObject:source];
	});
}

- (void) _closeStream
{
	[self doComplete];
}

#pragma mark -
#pragma mark StreamObserver inside Stream
- (void) stream:(SPDataStream*)stream hasIncomingData:(id)value
{

}

- (void) stream:(SPDataStream*)stream willUpdatedWith:(id)value
{

}

- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value
{
	[self doNext:value];
}

- (void) stream:(SPDataStream*)stream gotError:(NSError*)error
{
	[self doError:error];
}

- (void) streamCompleted:(SPDataStream*)stream
{
	[self doComplete];
}
@end

@interface SPDataBinder () <SPDataStreamObserver>
{
	SPDataBinder *_agent;
	dispatch_queue_t _queue;
	SomePromiseThread *_thread;
}
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, weak) id object;

@end

@implementation SPDataBinder

- (instancetype) init
{
	[self doesNotRecognizeSelector:_cmd];
	self = [self initWith:nil keyPath:nil];
	return nil;
}

- (instancetype)initWith:(id) object keyPath:(NSString*)keyPath
{
	self = [super init];
	if(self)
	{
		self.object = object;
		@sp_avoidblockretain(self)
			[self.object spAddDestroyListener:^(NSDictionary *msg) {
				@sp_strongify(self)
				guard(self) else return;
				[self discard];
			} message:nil];
		@sp_avoidend(self)
		self.keyPath = keyPath;
	}
	
	return self;
}

- (instancetype) initWith:(id) object keyPath:(NSString*)keyPath queue:(dispatch_queue_t)queue
{
	self = [self initWith:object keyPath:keyPath];
	if(self)
	{
		_queue = queue;
	}
	return self;
}

- (instancetype) initWith:(id) object keyPath:(NSString*)keyPath thread:(SomePromiseThread*)thread
{
	self = [self initWith:object keyPath:keyPath];
	if(self)
	{
		_thread = thread;
	}
	return self;
}

- (void) setStream:(SPDataStream *)stream
{
	guard(_object) else {return;}
	if(_stream) {[_stream removeObserver:self];}
	_stream = stream;
	_agent = self;
	[_stream addObserver:self];
}

- (void) discard
{
	_agent = nil;
	[_stream removeObserver:self];
	_stream = nil;
}

- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value
{
	if(stream == _stream)
	{
		__strong id strongObject = _object;
		if(_queue)
		{
			dispatch_async(_queue, ^{
				[strongObject setValue:value forKey:self->_keyPath];
			});
		}
		else if(_thread)
		{
			[_thread performBlock:^{
				[strongObject setValue:value forKey:self->_keyPath];
			}];
		}
		else
		{
			[strongObject setValue:value forKey:_keyPath];
		}
	}
}

- (void) streamCompleted:(SPDataStream*)stream
{
	if(stream == _stream)
	{
		[self discard];
	}
}

@end


@interface SPAction() <SPDataStreamObserver>
{
	SPAction *_agent;
	SomePromiseThread *_thread;
	dispatch_queue_t _queue;
}

@property (nonatomic, copy) SPActionBlock action;
@property (nonatomic, weak) NSObject *object;

@end

@implementation SPAction

- (instancetype) init
{
	[self doesNotRecognizeSelector:_cmd];
	self = [self initWithAssociatedObject:self action:^(id object){}];
	return nil;
}

- (void) setStream:(SPDataStream *)stream
{
	guard(_object) else {return;}
	if(_stream) {[_stream removeObserver:self];}
	_stream = stream;
	_agent = self;
	[_stream addObserver:self];
}

- (void) setThread:(SomePromiseThread *)thread
{
	guard(self.stream == nil) else return;
	_thread = thread;
	_queue = nil;
}

- (void) setQueue:(dispatch_queue_t)queue
{
	guard(self.stream == nil) else return;
	_queue = queue;
	_thread = nil;
}

//associated object is used for action life time.
- (instancetype) initWithAssociatedObject:(id)object action:(SPActionBlock)action
{
	self = [super init];
	if(self)
	{
		self.object = object;
		@sp_avoidblockretain(self)
			[self.object spAddDestroyListener:^(NSDictionary *msg) {
				@sp_strongify(self)
				guard(self) else return;
				[self discard];
			} message:nil];
		@sp_avoidend(self)
	
		self.action = action;
	}
	return self;
}

- (instancetype) initWithAssociatedObject:(id _Nonnull)object action:(SPActionBlock _Nonnull)action queue:(dispatch_queue_t)queue
{
	self = [self initWithAssociatedObject:object action:action];
	if(self)
	{
		_queue = queue;
	}
	return self;
}

- (instancetype) initWithAssociatedObject:(id _Nonnull)object action:(SPActionBlock _Nonnull)action thread:(SomePromiseThread *)thread
{
	self = [self initWithAssociatedObject:object action:action];
	if(self)
	{
		_thread = thread;
	}
	return self;
}

- (void) discard
{
	_agent = nil;
	[self.stream removeObserver:self];
	self.stream = nil;
}

- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value
{
	if(stream == _stream)
	{
		@sp_avoidblockretain(self)
			if(_queue)
			{
				dispatch_async(_queue, ^{
					@sp_strongify(self)
					guard(self) else return;
					self.action(self.stream.lastResult);
				});
			}
			else if(_thread)
			{
				[_thread performBlock:^{
					@sp_strongify(self)
					guard(self) else return;
					self.action(self.stream.lastResult);
				}];
			}
			else
			{
				@sp_strongify(self)
				guard(self) else return;
				self.action(self.stream.lastResult);
			}
		@sp_avoidend(self)
	}
}

- (void) streamCompleted:(SPDataStream*)stream
{
	if(stream == _stream)
	{
		[self discard];
	}
}

@end


@interface __SPCommandExecutor : NSObject
{
	SPDataStream *_stream;
	__SPCommandExecutor *_agent;
}
@end

@implementation __SPCommandExecutor

- (instancetype)initWithStream:(SPDataStream*)stream owner:(NSObject<SPDataStreamObserver>*)owner
{
	self = [super init];
	
	if(self)
	{
		_stream = stream;
		[_stream addObserver:owner];
		@sp_avoidblockretain(self)
			_stream.onComplete(^(SPDataStream *stream){
				@sp_strongify(self)
				guard(self) else return;
				self->_agent = nil;
			});
			[owner spAddDestroyListener:^(NSDictionary *msg) {
				@sp_strongify(self)
				guard(self) else return;
				if(self->_stream)
				{
					[self->_stream doComplete];
				}
				self->_agent = nil;
			} message:nil];
		
		@sp_avoidend(self)
	}
	
	return self;
}

- (void) execute
{
	_agent = self;
}

@end

@interface SPCommand() <SPDataStreamObserver>

@property(nonatomic, copy)SPCommandEnableBlock enableBlock;
@property(nonatomic, copy)SPCommandDataStreamBlock streamBlock;
@property(nonatomic, copy)SPCommandDoNextBlock nextBlock;
@property(nonatomic, copy)SPCommandDoErrorBlock errorBlock;
@property(nonatomic, copy)SPCommandDoCompleteBlock completeBlock;

@end

@implementation SPCommand

- (instancetype)initWithEnableBlock:(SPCommandEnableBlock _Nullable)enableBlock
						streamBlock:(SPCommandDataStreamBlock _Nonnull)streamBlock
							 doNext:(SPCommandDoNextBlock _Nonnull)doNextBlock
							doError:(SPCommandDoErrorBlock _Nullable)doErrorBlock
						 doComplete:(SPCommandDoCompleteBlock _Nullable)doCompleteBlock
{
	self = [super init];
	
	if(self)
	{
		self.enableBlock = enableBlock;
		self.streamBlock = streamBlock;
		self.nextBlock = doNextBlock;
		self.errorBlock = doErrorBlock;
		self.completeBlock = doCompleteBlock;
	}
	
	return self;
}

- (BOOL) execute:(id) input
{
	guard(_streamBlock) else return NO;
	BOOL available = YES;
	if(_enableBlock)
	{
		available = _enableBlock();
	}
	guard(available) else return NO;
	SPDataStream *_stream = _streamBlock(input);
	[[[__SPCommandExecutor alloc] initWithStream:_stream owner:self] execute];
	return YES;
}


- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value
{
	self.nextBlock(value);
}

- (void) stream:(SPDataStream*)stream gotError:(NSError*)error
{
	if(self.errorBlock)
	{
		self.errorBlock(error);
	}
}

- (void) streamCompleted:(SPDataStream*)stream
{
	if(self.completeBlock)
	{
		self.completeBlock();
	}
}

@end

@implementation NSObject (SPDataStream)

- (SPDataStream*) createSPStream:(NSString*)keyPath times:(NSInteger)times
{
	return [SPDataStream newWithSource:self keyPath:keyPath times:times];
}

- (SPDataStream*) createSPStream:(NSString*)keyPath onQueue:(dispatch_queue_t)queue times:(NSInteger)times
{
	return [SPDataStream newWithSource:self keyPath:keyPath queue:queue times:times];
}

- (SPDataStream*) createSPStream:(NSString *)keyPath onThread:(SomePromiseThread*)thread times:(NSInteger)times
{
	return [SPDataStream newWithSource:self keyPath:keyPath thread:thread times:times];
}

- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath times:(NSInteger)times
{
	SPDataStream *stream = [SPDataStream newWithSource:object keyPath:keyPath times:times];
	[stream addSource:self keyPath:keyPath closeOnDestroy:NO];
	return stream;
}

- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onQueue:(dispatch_queue_t)queue times:(NSInteger)times
{
	SPDataStream *stream = [SPDataStream newWithSource:object keyPath:keyPath queue:queue times:times];
	[stream addSource:self keyPath:keyPath closeOnDestroy:NO];
	return stream;
}

- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onThread:(SomePromiseThread*)thread  times:(NSInteger)times
{
	SPDataStream *stream = [SPDataStream newWithSource:object keyPath:keyPath thread:thread times:times];
	[stream addSource:self keyPath:keyPath closeOnDestroy:NO];
	return stream;
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, NSInteger))createSPStream
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString *, NSInteger) = ^SPDataStream*(NSString *key, NSInteger times)
   	{
      @sp_strongify(self)
      return [self createSPStream:self keyPath:key times:times];
	};
   return [block copy];
   @sp_avoidend(self)
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, id _Nonnull, NSInteger))createSPStreamForObject
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString *, id, NSInteger) = ^SPDataStream*(NSString *key, id object, NSInteger times)
   	{
      @sp_strongify(self)
      return [self createSPStream:object keyPath:key times:times];
	};
   return [block copy];
   @sp_avoidend(self)
}

@end

@implementation NSProxy (SPDataStream)

- (SPDataStream*) createSPStream:(NSString*)keyPath times:(NSInteger)times
{
	return [SPDataStream newWithSource:self keyPath:keyPath times:times];
}

- (SPDataStream*) createSPStream:(NSString*)keyPath onQueue:(dispatch_queue_t)queue times:(NSInteger)times
{
	return [SPDataStream newWithSource:self keyPath:keyPath queue:queue times:times];
}

- (SPDataStream*) createSPStream:(NSString *)keyPath onThread:(SomePromiseThread*)thread times:(NSInteger)times
{
	return [SPDataStream newWithSource:self keyPath:keyPath thread:thread times:times];
}

- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath times:(NSInteger)times
{
	SPDataStream *stream = [SPDataStream newWithSource:object keyPath:keyPath times:times];
	[stream addSource:self keyPath:keyPath closeOnDestroy:NO];
	return stream;
}

- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onQueue:(dispatch_queue_t)queue times:(NSInteger)times
{
	SPDataStream *stream = [SPDataStream newWithSource:object keyPath:keyPath queue:queue times:times];
	[stream addSource:self keyPath:keyPath closeOnDestroy:NO];
	return stream;
}

- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onThread:(SomePromiseThread*)thread times:(NSInteger)times
{
	SPDataStream *stream = [SPDataStream newWithSource:object keyPath:keyPath thread:thread times:times];
	[stream addSource:self keyPath:keyPath closeOnDestroy:NO];
	return stream;
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, NSInteger))createSPStream
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString *, NSInteger) = ^SPDataStream*(NSString *key, NSInteger times)
   	{
      @sp_strongify(self)
      return [self createSPStream:self keyPath:key times:times];
	};
   return [block copy];
   @sp_avoidend(self)
}

- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, id _Nonnull, NSInteger))createSPStreamForObject
{
	@sp_avoidblockretain(self)
   	SPDataStream*(^block)(NSString *, id, NSInteger) = ^SPDataStream*(NSString *key, id object, NSInteger times)
   	{
      @sp_strongify(self)
      return [self createSPStream:object keyPath:key times:times];
	};
   return [block copy];
   @sp_avoidend(self)
}

@end
