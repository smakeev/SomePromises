//
//  SomePromiseTypes.m
//  SomePromises
//
//  Created by Sergey Makeev on 24/05/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SomePromise.h"

#import <objc/runtime.h>

#define EMPTY_AVAILABLE + (instancetype)empty { return [[[self class] alloc] init]; }

PromiseWorker promiseWorker(SomePromiseThread *thread)
{
   PromiseWorker worker = [[SomePromiseSettingsPromiseWorker alloc] init];
   worker.thread = thread;
   return worker;
}

PromiseWorker promiseWorkerWithName(NSString *name)
{
   PromiseWorker worker = [[SomePromiseSettingsPromiseWorker alloc] init];
   worker.thread = [SomePromiseThread threadWithName:name];
   return worker;
}

PromiseWorker promiseWorkerWithQueue(dispatch_queue_t queue)
{
   PromiseWorker worker = [[SomePromiseSettingsPromiseWorker alloc] init];
   worker.queue = queue;
   return worker;
}

DelegateWorker delegateWorker(SomePromiseThread *thread)
{
   DelegateWorker worker =  [[SomePromiseSettingsPromiseDelegateWorker alloc] init];
   worker.thread = thread;
   return worker;
}

DelegateWorker delegateWorkerWithName(NSString *name)
{
   DelegateWorker worker = [[SomePromiseSettingsPromiseDelegateWorker alloc] init];
   worker.thread = [SomePromiseThread threadWithName:name];
   return worker;
}

DelegateWorker delegateWorkerWithQueue(dispatch_queue_t queue)
{
   DelegateWorker worker = [[SomePromiseSettingsPromiseDelegateWorker alloc] init];
   worker.queue = queue;
   return worker;
}

SomeProgressBlockProvider* progressProvider()
{
	return [[SomeProgressBlockProvider alloc] init];
}

SomeIsRejectedBlockProvider* isRejectedProvider()
{
   return [[SomeIsRejectedBlockProvider alloc] init];
}

SomeParameterProvider* parameterProvider(id value)
{
	SomeParameterProvider *provider = [[SomeParameterProvider alloc] init];
	provider.value = value;
	return provider;
}

SomeParameterProvider* weakParameterProvider(id value)
{
	SomeParameterProvider *provider = [[SomeParameterProvider alloc] init];
	provider.weakValue = value;
	return provider;
}

SomeResultProvider* resultProvider(void)
{
   return [[SomeResultProvider alloc] init];
}

SomeValuesInChainProvider* valuesProvider(void)
{
   return [[SomeValuesInChainProvider alloc] init];
}

@implementation SomePromiseSettingsQueueOrThread
EMPTY_AVAILABLE
@synthesize thread;
@synthesize queue;
@end

@implementation SomePromiseSettingsPromiseWorker
EMPTY_AVAILABLE
@end

@implementation SomePromiseSettingsPromiseDelegateWorker
EMPTY_AVAILABLE
@end

@class ObserverAsyncWayWrapper;
@implementation SomePromiseSettingsObserverWrapper
EMPTY_AVAILABLE
@synthesize observers = _observers;

- (instancetype)init
{
   self = [super init];
   if(self)
   {
      _observers = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
   }
   return self;
}

- (void) addObserver:(id<SomePromiseObserver>)observer onQueue:(dispatch_queue_t)queue
{
    ObserverAsyncWayWrapper *worker = [[ObserverAsyncWayWrapper alloc] init];
    worker.queue = queue;
    [_observers setObject:worker forKey:observer];
}

- (void) addObserver:(id<SomePromiseObserver>)observer onThread:(SomePromiseThread*)thread
{
    ObserverAsyncWayWrapper *worker = [[ObserverAsyncWayWrapper alloc] init];
    worker.thread = thread;
    [_observers setObject:worker forKey:observer];
}

- (void) addObservers:(NSArray<id<SomePromiseObserver> >*)observers onQueue:(dispatch_queue_t)queue
{
    for(id<SomePromiseObserver> observer in observers)
    {
        ObserverAsyncWayWrapper *worker = [[ObserverAsyncWayWrapper alloc] init];
        worker.queue = queue;
	    [_observers setObject:worker forKey:observer];
	}
}
- (void) addObservers:(NSArray<id<SomePromiseObserver> >*)observers onThread:(SomePromiseThread*)thread
{
    for(id<SomePromiseObserver> observer in observers)
    {
        ObserverAsyncWayWrapper *worker = [[ObserverAsyncWayWrapper alloc] init];
        worker.thread = thread;
	    [_observers setObject:worker forKey:observer];
	}
}

- (void) removeObserver:(id<SomePromiseObserver>)observer
{
    [_observers removeObjectForKey:observer];
}

- (void) clear
{
    [_observers removeAllObjects];
}

@end

@implementation SomePromiseSettingsOnSuccessBlocksWrapper
EMPTY_AVAILABLE
@synthesize onSuccessBlocks;
-(NSMutableArray<OnSuccessBlock> *)onSuccessBlocks
{
   if(onSuccessBlocks)
   {
	  return onSuccessBlocks;
   }
   else return [NSMutableArray new];
}

@end

@implementation SomePromiseSettingsOnRejectBlocksWrapper
EMPTY_AVAILABLE
@synthesize onRejectBlocks;
-(NSMutableArray<OnRejectBlock> *)onRejectBlocks
{
   if(onRejectBlocks)
   {
	  return onRejectBlocks;
   }
   else return [NSMutableArray new];
}
@end

@implementation SomePromiseSettingsOnProgressBlocksWrapper
EMPTY_AVAILABLE
@synthesize onProgressBlocks;
-(NSMutableArray<OnProgressBlock> *)onProgressBlocks
{
   if(onProgressBlocks)
   {
	  return onProgressBlocks;
   }
   else return [NSMutableArray new];
}
@end

@implementation SomePromiseSettingsResolvers
@synthesize initBlock;
@synthesize futureBlock;
@synthesize noFutureBlock;
@synthesize finalResultBlock;
@end

@implementation SomePromiseDelegateWrapper
@synthesize delegate;
@end

@implementation SomeProgressBlockProvider
@synthesize progressBlock;
@end

@implementation SomeParameterProvider
@synthesize value;
@synthesize weakValue;
@end

@implementation SomeIsRejectedBlockProvider
@synthesize isRejectedBlock;
@end

@implementation SomeResultProvider
@synthesize result;
@synthesize error;
@synthesize finished;
@end

@implementation SomeValuesInChainProvider
@synthesize chain;
@end

@interface SomePromiseSettings ()
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
@end

@implementation SomePromiseSettings

@synthesize name;
@synthesize status;
@synthesize resolvers;
@synthesize observers;
@synthesize worker;
@synthesize futureClass;
@synthesize delegate;
@synthesize delegateWorker = _delegateWorker;
@synthesize onSuccessBlocks = _onSuccessBlocks;
@synthesize onRejectBlocks = _onRejectBlocks;
@synthesize onProgressBlocks = _onProgressBlocks;
@synthesize error;
@synthesize ownerError;
@synthesize value;
@synthesize ownerValue;
@synthesize resolved;
@synthesize forcedRejected;
@synthesize chain;
@synthesize parameters;

-(SomePromiseSettingsPromiseDelegateWorker*) delegateWorker
{
   if(_delegateWorker)
      return _delegateWorker;
   return [SomePromiseSettingsPromiseDelegateWorker empty];
}

- (SomePromiseSettingsOnSuccessBlocksWrapper*) onSuccessBlocks
{
   if(_onSuccessBlocks)
      return _onSuccessBlocks;
   return [SomePromiseSettingsOnSuccessBlocksWrapper empty];
}

- (SomePromiseSettingsOnRejectBlocksWrapper*) onRejectBlocks
{
   if(_onRejectBlocks)
      return _onRejectBlocks;
   return [SomePromiseSettingsOnRejectBlocksWrapper empty];
}

- (SomePromiseSettingsOnProgressBlocksWrapper*) onProgressBlocks
{
   if(_onProgressBlocks)
      return _onProgressBlocks;
   return [SomePromiseSettingsOnProgressBlocksWrapper empty];
}

- (BOOL) consistent
{
    guard (self.name) else {return NO;}
	guard (self.status != ESomePromiseUnknown) else {return NO;}
	guard (self.resolvers) else {return NO;}
	guard (self.worker) else {return NO;}
	
	switch(self.status)
	{
	   case ESomePromiseUnknown:
	        return NO;
	   case ESomePromiseNonActive:
	   case ESomePromisePending:
	        guard(self.error == nil && self.value == nil) else {return NO;}
	        break;
	   case ESomePromiseSuccess:
			guard(self.error == nil && self.value != nil) else {return NO;}
			break;
	   case ESomePromiseRejected:
			guard(self.value == nil) else {return NO;}
			break;
	}
	
	guard ((self.worker.thread || self.worker.queue) && !(self.worker.thread && self.worker.queue)) else {return NO;}
	
	if(self.delegate)
	{
	   guard(self.delegateWorker) else {return NO;}
	}
	
	return YES;
}

- (SomePromiseSettings*) freshCopy
{
	SomePromiseSettings *newSettings = [[SomePromiseSettings alloc] init];
	newSettings.name = self.name;
	newSettings.status = ESomePromiseNonActive;
	newSettings.futureClass = self.futureClass;
	newSettings.resolvers = self.resolvers;
	newSettings.observers = self.observers;
	newSettings.worker = self.worker;
	newSettings.delegate = self.delegate;
	newSettings.delegateWorker = self.delegateWorker;
    newSettings.onSuccessBlocks = self.onSuccessBlocks;
    newSettings.onRejectBlocks = self.onRejectBlocks;
	newSettings.onProgressBlocks = self.onProgressBlocks;
    newSettings.error = nil;
    newSettings.ownerError = self.ownerError;
    newSettings.value = nil;
    newSettings.ownerValue = self.ownerValue;
    newSettings.resolved = NO;
    newSettings.forcedRejected = NO;
    newSettings.chain = self.chain;
	newSettings.parameters = [self.parameters mutableCopy];
	
    return newSettings;
}

- (SomePromiseMutableSettings*) mutableCopy
{
   SomePromiseMutableSettings *newSettings = [[SomePromiseMutableSettings alloc] init];
	newSettings.name = self.name;
	newSettings.status = self.status;
	newSettings.futureClass = self.futureClass;
	newSettings.resolvers = self.resolvers;
	newSettings.observers = self.observers;
	newSettings.worker = self.worker;
	newSettings.delegate = self.delegate;
	newSettings.delegateWorker = self.delegateWorker;
    newSettings.onSuccessBlocks = self.onSuccessBlocks;
    newSettings.onRejectBlocks = self.onRejectBlocks;
	newSettings.onProgressBlocks = self.onProgressBlocks;
    newSettings.error = self.error;
    newSettings.ownerError = self.ownerError;
    newSettings.value = self.value;
    newSettings.ownerValue = self.ownerValue;
    newSettings.resolved = self.value;
    newSettings.forcedRejected = self.forcedRejected;
    newSettings.chain = self.chain;
    newSettings.parameters = [self.parameters mutableCopy];
   return newSettings;
}

@end

@implementation SomePromiseMutableSettings
@dynamic name;
@dynamic status;
@dynamic futureClass;
@dynamic resolvers;
@dynamic observers;
@dynamic worker;
@dynamic delegate;
@dynamic delegateWorker;

@dynamic onSuccessBlocks;
@dynamic onRejectBlocks;
@dynamic onProgressBlocks;
@dynamic error;
@dynamic ownerError;
@dynamic value;
@dynamic ownerValue;
@dynamic resolved;
@dynamic forcedRejected;
@dynamic chain;
@dynamic parameters;

- (SomePromiseSettings*) copy
{
    SomePromiseSettings *newSettings = [[SomePromiseSettings alloc] init];
	newSettings.name = self.name;
	newSettings.status = self.status;
	newSettings.futureClass = self.futureClass;
	newSettings.resolvers = self.resolvers;
	newSettings.observers = self.observers;
	newSettings.worker = self.worker;
	newSettings.delegate = self.delegate;
	newSettings.delegateWorker = self.delegateWorker;
    newSettings.onSuccessBlocks = self.onSuccessBlocks;
    newSettings.onRejectBlocks = self.onRejectBlocks;
	newSettings.onProgressBlocks = self.onProgressBlocks;
    newSettings.error = self.error;
    newSettings.ownerError = self.ownerError;
    newSettings.value = self.value;
    newSettings.ownerValue = self.ownerValue;
    newSettings.resolved = self.value;
    newSettings.forcedRejected = self.forcedRejected;
    newSettings.chain = self.chain;
    newSettings.parameters = [self.parameters mutableCopy];
   return newSettings;
}
@end

////////////////// SPMapTable;


@interface __SPMapTableKeyContainer: NSObject <NSCopying>
{
   NSUInteger _hash;
   __weak SPMapTable *_table;
}
@property (nonatomic, weak) id<NSObject> value;
@end


@interface __SPMapTableWeakKeyWatcher : NSObject
{
     __weak SPMapTable *_table;
     __weak __SPMapTableKeyContainer *_key;
}
@end

@implementation __SPMapTableWeakKeyWatcher

- (void) setKey:(__SPMapTableKeyContainer*)key
{
   _key = key;
}

- (instancetype) initWithTable:(SPMapTable*) table key:(__SPMapTableKeyContainer*)key
{
    self = [super init];
	
    if(self)
    {
		_table = table;
		_key = key;
	}
	
	return self;
}

- (void) dealloc
{
	[_table removeObjectForKey:_key];
}

@end

static char const * const ObjectTagKey = "SPMapTableWeakKeyWatcher";

@implementation __SPMapTableKeyContainer

- (instancetype) initWithTable:(SPMapTable*)table
{
   self = [super init];
	
   if(self)
   {
      _table = table;
   }

   return self;
}

- (void) setValue:(id<NSObject>)value
{
   _value = value;
   _hash = _value.hash;
   __SPMapTableWeakKeyWatcher *watcher = objc_getAssociatedObject(value, ObjectTagKey);
   if(watcher == nil)
   {
       watcher = [[__SPMapTableWeakKeyWatcher alloc] initWithTable:_table key:self];
       objc_setAssociatedObject(value, ObjectTagKey, watcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}


- (NSUInteger) hash
{
   return _hash;
}

- (BOOL) isEqual:(id)object
{
   return [self.value isEqual:object];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
   __SPMapTableKeyContainer *newCopy = [[__SPMapTableKeyContainer alloc] init];
   newCopy.value = self.value;
   __SPMapTableWeakKeyWatcher *watcher = objc_getAssociatedObject(self.value, ObjectTagKey);
   [watcher setKey:newCopy];
   return newCopy;
}

@end


@interface SPMapTable()
{
   dispatch_queue_t _syncQueue;
   NSMutableDictionary *_store;
}

@end;

@implementation SPMapTable

+ (instancetype) new
{
    return [[SPMapTable alloc] init];
}

- (instancetype) init
{
   self = [super init];
	
   if(self)
   {
	   _syncQueue = dispatch_queue_create("__SPMapTableStore_queue", DISPATCH_QUEUE_SERIAL);
	   _store = [NSMutableDictionary new];
   }
	
   return self;
}

- (id) objectForKey:(id)key
{
   __block id object = nil;
   dispatch_sync(_syncQueue, ^
   {
       object = self->_store[key];
   });
   return object;
}

- (NSUInteger) count
{
   __block NSUInteger count = 0;
   dispatch_sync(_syncQueue, ^
   {
       count = self->_store.count;
   });
   return count;
}

- (void) setObject:(id)object forKey:(id)key
{
	dispatch_sync(_syncQueue, ^
	{
	    __SPMapTableKeyContainer *container = nil;
	    if(self->_store[key] == nil)
	    {
		   container = [[__SPMapTableKeyContainer alloc] initWithTable:self];
		   container.value = key;
		}
		[self->_store setObject:object forKey:container];
	});
}

- (NSEnumerator*) keyEnumerator
{
    __block NSEnumerator *enumerator = nil;
	dispatch_sync(_syncQueue, ^
	{
       NSMutableArray *array = [NSMutableArray new];
	   for (__SPMapTableKeyContainer *key in self->_store.allKeys)
	   {
	      if(key.value)
	      {
		     [array addObject:key.value];
		  }
	   }
	   enumerator = array.objectEnumerator;
	});
	
	return enumerator;
}

- (void) removeObjectForKey:(id)key
{
    dispatch_sync(_syncQueue, ^
    {
		guard([self->_store objectForKey:key]) else {return;}
		[self->_store removeObjectForKey:key];
	});
}

- (void) removeAllObjects
{
    dispatch_sync(_syncQueue, ^
    {
		[self->_store removeAllObjects];
    });
}

@end

@implementation SPPair

+ (instancetype) pairWithLeft:(id _Nullable)left right:(id _Nullable)right
{
   SPPair *pair =  [[SPPair alloc] init];
   pair.left = left;
   pair.right = right;
   return pair;
}

@end

SomeTuple createTuple(NSInteger number, ...)
{
	NSMutableArray *array = [NSMutableArray new];
	va_list args;
	va_start(args, number);
	for (int i =  0; i < number; ++i)
	{
		[array addObject:va_arg(args, id)];
	}
	va_end(args);
	return [^id (SomeTupleCommand command) {
		switch (command)
		{
			case SomeTupleGet:
				return [^NSArray*(void){
					return [array copy];
				} copy];
				break;
			case SomeTupleType:
				return [^Class(NSNumber *index) {
						return [array[index.integerValue] class];
				} copy];
				break;
			case SomeTupleCount:
				return [^NSNumber*(void) {
					return @(array.count);
				} copy];
				break;
			case SomeTupleValue:
				return [^id (id index){
					if ([index isKindOfClass:[NSNumber class]])
					{
						NSUInteger idx = ((NSNumber*)index).integerValue;
						if(idx >= array.count)
							return nil;
						return array[idx];
					}
					if ([index isKindOfClass:[NSString class]])
					{
						for(id element in array)
						{
							if([element isKindOfClass:[SPPair class]])
							{
								SPPair *pair = (SPPair*)element;
								if([pair.left isKindOfClass:[NSString class]])
								{
									if([pair.left isEqualToString:index])
									{
										return pair.right;
									}
								}
							}
						}
					}
					return nil;
				} copy];
				break;
			case SomeTupleGetNames:
				return[^NSArray*(void){
					NSMutableArray *result = [NSMutableArray new];
					for(id element in array)
					{
						if([element isKindOfClass:[SPPair class]])
						{
							SPPair *pair = (SPPair*)element;
							if([pair.left isKindOfClass:[NSString class]])
							{
								[result addObject:pair.left];
							}
						}
					}
					return [result copy];
				} copy];
				break;
			case SomeTupleName:
				return[^NSString*(NSNumber *idx){
				    NSUInteger index = [idx integerValue];
					if(index >= array.count)
						return nil;
					SPPair *element = array[index];
					if(![element isKindOfClass:[SPPair class]])
						return nil;
					if(![element.left isKindOfClass:[NSString class]])
						return nil;
					return element.left;
				} copy];
				break;
		}
		return nil;
	} copy];
}


@implementation SPTuple

+ (SPTuple*) new:(SomeTuple)tuple
{
	SPTuple *new = [[SPTuple alloc] init];
	new.tuple =  tuple;
	return new;
}

+ (NSInteger) countForTuple:(SomeTuple)tuple
{
	return [tuple(SomeTupleCount)(nil) integerValue];
}

+ (id) valueForTuple:(SomeTuple)tuple at:(NSUInteger) index
{
	return tuple(SomeTupleValue)(@(index));
}

+ (Class) typeForTuple:(SomeTuple)tuple at:(NSUInteger) index
{
	return tuple(SomeTupleType)(@(index));
}

+ (id) valueForTuple:(SomeTuple) tuple withName:(NSString*)name
{
	return tuple(SomeTupleValue)(name);
}

+ (NSString*) nameForTuple:(SomeTuple)tuple at:(NSUInteger) number
{
	return tuple(SomeTupleName)(@(number));
}

+ (NSArray<NSString*>*) namesForTuple:(SomeTuple) tuple
{
	return tuple(SomeTupleGetNames)(nil);
}

+ (NSArray*) getValuesForTuple:(SomeTuple) tuple
{
	return tuple(SomeTupleGet)(nil);
}

- (NSInteger) count
{
	return [SPTuple countForTuple:self.tuple];
}

- (id) valueAt:(NSUInteger) index
{
	return [SPTuple valueForTuple:self.tuple at:index];
}

- (Class) typeAt:(NSUInteger) index
{
	return [SPTuple typeForTuple:self.tuple at:index];
}

- (id) valueByName:(NSString*) name
{
	return [SPTuple valueForTuple:self.tuple withName:name];
}

- (NSString *_Nullable) nameAt:(NSUInteger) index
{
	return [SPTuple nameForTuple:self.tuple at:index];
}

- (NSArray<NSString*>*) names
{
	return [SPTuple namesForTuple:self.tuple];
}

- (NSArray*) getValues
{
	return [SPTuple getValuesForTuple:self.tuple];
}

@end

#pragma mark
#pragma mark SPArray

@interface SPArrayElementWrapper ()
- (void) setValue:(id)value;
@end

@implementation SPArrayElementWrapper

- (id) value
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void) setValue:(id)value
{
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL) weakly
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (NSString*) description
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end

@interface __SPArrayElementWrapperStrong : SPArrayElementWrapper
@property (nonatomic, readwrite, strong) id value;
@end

@interface __SPArrayElementWrapperWeak ()
@property (nonatomic, readwrite, weak) id value;
@property (nonatomic, weak) SPArray *array;
@end

@implementation __SPArrayElementWrapperWeak

- (instancetype) initWithValue:(id)value
{
	self = [super init];
	if(self)
	{
		self.value = value;
	}
	return self;
}

- (NSString*) description
{
	return ((NSObject*)_value).description;
}

- (void) setValue:(id)value
{
	guard(value) else return;
	_value = value;

	@sp_avoidblockretain(self)
	((NSObject*)value).spDestroyListener(nil, ^(NSDictionary *msg){
		@sp_strongify(self)
		guard(self && self.array) else return;
		if(self.array.autoshrink)
		{
			[self.array shrink];
		}
	});
	@sp_avoidend(self)
}

- (BOOL) weakly
{
	return YES;
}

@end

@implementation __SPArrayElementWrapperStrong

- (BOOL) weakly
{
	return NO;
}

- (NSString*) description
{
	return ((NSObject*)_value).description;
}

@end

@interface SPArray ()
{
	NSMutableArray<SPArrayElementWrapper*> *_array;
	dispatch_queue_t _syncQueue;
	NSUInteger _lockersNumber;
	NSCondition *_condition;
	BOOL _sorted;
}

@property (nonatomic, readwrite) BOOL changable;

- (instancetype) initInternal  NS_DESIGNATED_INITIALIZER;

@end

@interface __SPArrayEnumerator : NSEnumerator
{
	SPArray *_array;
	NSUInteger _currentIndex;
}

- (instancetype) initWithArray:(SPArray*)array;
@end

@implementation __SPArrayEnumerator

- (instancetype) initWithArray:(SPArray*)array
{
	self = [super init];
	if(self)
	{
		_array = array;
	}
	return self;
}

- (id) nextObject
{
	if(_currentIndex >= _array.count)
		return nil;
	return _array[_currentIndex++];
}

@end

@implementation SPArray
@synthesize autoshrink = _autoshrink;
@synthesize changable = _changable;

+ (instancetype) new
{
	return [[SPArray alloc] init];
}

+ (instancetype) array
{
	return [[SPArray alloc] init];
}
+ (instancetype) arrayWithCapacity:(NSUInteger)capacity
{
	return [[SPArray alloc] initWithCapacity:capacity];
}

+ (instancetype) fromArray:(NSArray*)array
{
	return [[SPArray alloc] initWithArray:array];
}

+ (instancetype) fromArrayWeakly:(NSArray*)array
{
	return [[SPArray alloc] initWithArrayWeakly:array];
}

+ (instancetype) arrayWithSPArray:(SPArray*)array
{
	return [[SPArray alloc] initWithSPArray:array];
}

- (instancetype) initInternal
{
	self = [super init];
	if(self)
	{
		_syncQueue = dispatch_queue_create("SPArray_queue", DISPATCH_QUEUE_SERIAL);
		_condition = [NSCondition new];
		_changable = YES;
	}
	return self;

}

- (instancetype) init
{
	self = [self initInternal];
	if(self)
	{
		_array = [NSMutableArray new];
	}
	return self;
}

- (instancetype) initWithCapacity:(NSUInteger)capacity
{
	self = [self initInternal];
	if(self)
	{
		_array = [NSMutableArray arrayWithCapacity:capacity];
	}
	return self;
}

- (instancetype) initWithArray:(NSArray*)array
{
	self = [self initInternal];
	if(self)
	{
		_array = [NSMutableArray arrayWithCapacity:array.count];
		for (id element in array)
		{
			if([element isKindOfClass:[SPArrayElementWrapper class]])
			{
				[_array addObject:element];
			}
			else
			{
				__SPArrayElementWrapperStrong *newElement = [[__SPArrayElementWrapperStrong alloc] init];
				newElement.value = element;
				[_array addObject:newElement];
			}
		}
	}
	return self;
}

- (instancetype) initWithArrayWeakly:(NSArray*)array
{
	self = [self initInternal];
	if(self)
	{
		_array = [NSMutableArray arrayWithCapacity:array.count];
		for (id element in array)
		{
			if([element isKindOfClass:[SPArrayElementWrapper class]])
			{
				[_array addObject:element];
			}
			else
			{
				__SPArrayElementWrapperWeak *newElement = [[__SPArrayElementWrapperWeak alloc] init];
				newElement.value = element;
				newElement.array = self;
				[_array addObject:newElement];
			}
		}
	}
	return self;
}

- (instancetype) initWithSPArray:(SPArray*)array
{
	self = [self initInternal];
	if(self)
	{
		array.changable = NO;
		_array = [array->_array mutableCopy];
		array.changable = YES;
	}
	return self;
}

- (NSUInteger) count
{
	__block NSUInteger result = 0;
	dispatch_sync(_syncQueue, ^{
		result = self->_array.count;
	});
	return result;
}

- (BOOL) autoshrink
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		result = self->_autoshrink;
	});
	return result;
}

- (void) setAutoshrink:(BOOL)autoshrink
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		self->_autoshrink = autoshrink;
		result = autoshrink;
	});
	if(result)
	{
		[self shrink];
	}
}

- (BOOL) changable
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		result = self->_changable;
	});
	return result;
}

- (void) setChangable:(BOOL)changable
{
	dispatch_sync(_syncQueue, ^{
		if(!changable)
		{
			self->_lockersNumber++;
		}
		else if(self->_lockersNumber > 0)
		{
			self->_lockersNumber--;
		}
	
		if (self->_lockersNumber == 0)
		{
			self->_changable = YES;
			[self->_condition signal];
		}
		else
		{
			self->_changable = NO;
		}
	});
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	return [self copy];
}

- (SPArray*) copy
{
	return [SPArray arrayWithSPArray:self];
}

- (id) objectAtIndexedSubscript:(NSUInteger)idx
{
	__block SPArrayElementWrapper *result = nil;
	dispatch_sync(_syncQueue, ^{
		result = self->_array[idx];
	});
	return result;
}

- (void) setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
	while(!self.changable)
	{
		[_condition wait];
	}
	
	dispatch_sync(_syncQueue, ^{
		if([obj isKindOfClass:[SPArrayElementWrapper class]])
		{
			self->_array[idx] = obj;
		}
		else
		{
			__SPArrayElementWrapperStrong *newElement = [[__SPArrayElementWrapperStrong alloc] init];
			newElement.value = obj;
			self->_array[idx] = newElement;
		}
		self->_sorted = NO;
	});
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
{
	BOOL stop = NO;
	NSUInteger index = 0;
	__block NSArray *array = nil;
	dispatch_sync(_syncQueue, ^{
		array = [self->_array copy];
	});
	for(SPArrayElementWrapper *obj in array)
	{
		block(obj.value, index++, &stop);
		if(stop)
		{
			break;
		}
	}
}

- (SPArray *(^ __nonnull)(void (^block)(id _Nullable obj, NSUInteger idx, BOOL *stop)))enumerateObjectsUsingBlock
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void (^block)(id _Nullable obj, NSUInteger idx, BOOL *stop)){
			@sp_strongify(self)
			guard(self) return nil;
			[self enumerateObjectsUsingBlock:[block copy]];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (void)reverslyEnumerateObjectsUsingBlock:(void (^)(id _Nullable obj, NSUInteger idx, BOOL *stop))block
{
	BOOL stop = NO;
	__block NSArray *array = nil;
	dispatch_sync(_syncQueue, ^{
		array = [self->_array copy];
	});

	for(NSUInteger i = array.count; i > 0 ; --i)
	{
		SPArrayElementWrapper *obj = array[i - 1];
		block(obj.value, i - 1, &stop);
		if(stop)
		{
			break;
		}
	}
}

- (SPArray *_Nonnull(^ __nonnull)(void (^block)(id _Nullable obj, NSUInteger idx, BOOL *stop)))reverslyEnumerateObjectsUsingBlock
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void (^block)(id _Nullable obj, NSUInteger idx, BOOL *stop)){
			@sp_strongify(self)
			guard(self) return nil;
			[self reverslyEnumerateObjectsUsingBlock:[block copy]];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (NSEnumerator*)objectEnumerator
{
	return [[__SPArrayEnumerator alloc] initWithArray:[self copy]];
}

- (NSEnumerator*)reversedObjectEnumerator
{
	return [[__SPArrayEnumerator alloc] initWithArray:[self reversed]];
}

- (void)forEach:(SPArrayForEachBlock) block
{
	dispatch_sync(_syncQueue, ^{
		BOOL stop = NO;
		for(SPArrayElementWrapper *obj in self->_array)
		{
			NSUInteger index = 0;
			block(obj.value, index++, &stop);
			if(stop)
			{
				break;
			}
		}
	});
}

- (SPArray *(^ __nonnull)(SPArrayForEachBlock block))forEach
{
		@sp_avoidblockretain(self)
		return [^SPArray*(SPArrayForEachBlock block){
			@sp_strongify(self)
			guard(self) return nil;
			[self forEach:[block copy]];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len
{
	NSUInteger count = 0;
	unsigned long countOfItemsAlreadyEnumerated = state->state;
	if(countOfItemsAlreadyEnumerated == 0)
	{
		state->mutationsPtr = &state->extra[0];
		self.changable = NO;
	}
	if(countOfItemsAlreadyEnumerated < self.count)
	{
		state->itemsPtr = buffer;
		while((countOfItemsAlreadyEnumerated < self.count) && count < len)
		{
			dispatch_sync(_syncQueue, ^{
				buffer[count] = self->_array[countOfItemsAlreadyEnumerated];
			});
			countOfItemsAlreadyEnumerated++;
			count++;
		}
	}
	else
	{
		count = 0;
		self.changable = YES;
	}
	
	state->state = countOfItemsAlreadyEnumerated;
	return count;
}

- (void) shrink
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		NSMutableArray *elementsToBeShrinked = [NSMutableArray new];
		for (SPArrayElementWrapper *element in self->_array)
		{
			if(element.value == nil)
			{
				[elementsToBeShrinked addObject:element];
			}
		}
		[self->_array removeObjectsInArray:elementsToBeShrinked];
	});
}

- (SPArray*) shrinked
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray shrink];
	return newArray;
}

- (SPArray *(^)(void))shrinking
{
	@sp_avoidblockretain(self)
		return [^SPArray*{
			@sp_strongify(self)
			guard(self) return nil;
			return [self shrinked];
		} copy];
	@sp_avoidend(self)
}

- (void) add:(id)obj
{
	while(!self.changable)
	{
		[_condition wait];
	}
	BOOL shrinking = self.autoshrink;
	dispatch_sync(_syncQueue, ^{
		if([obj isKindOfClass:[SPArrayElementWrapper class]])
		{
			if(shrinking && ((SPArrayElementWrapper*)obj).value == nil)
				return;
			[self->_array addObject:obj];
		}
		else
		{
			if(shrinking && obj == nil)
				return;
			__SPArrayElementWrapperStrong *newElement = [[__SPArrayElementWrapperStrong alloc] init];
			newElement.value = obj;
			[self->_array addObject:newElement];
		}
		self->_sorted = NO;
	});
}

- (SPArray*) added:(id)object
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray add:object];
	return newArray;
}

- (SPArray *(^ __nonnull)(id object))add
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object){
			@sp_strongify(self)
			guard(self) return nil;
			[self add:object];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(id object))adding
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object){
			@sp_strongify(self)
			guard(self) return nil;
			return [self added:object];
		} copy];
	@sp_avoidend(self)
}

- (void) addWeakly:(id)object
{
	while(!self.changable)
	{
		[_condition wait];
	}
	BOOL shrinking = self.autoshrink;
	dispatch_sync(_syncQueue, ^{
		id objectToAdd = object;
		if([object isKindOfClass:[SPArrayElementWrapper class]])
		{
			if(shrinking && ((SPArrayElementWrapper*)object).value == nil)
				return;
			objectToAdd = ((SPArrayElementWrapper*)object).value;
		}
		if(shrinking && object == nil)
			return;
		__SPArrayElementWrapperWeak *newElement = [[__SPArrayElementWrapperWeak alloc] init];
		newElement.value = objectToAdd;
		newElement.array = self;
		[self->_array addObject:newElement];
		self->_sorted = NO;
	});
}

- (SPArray*) addedWeakly:(id)object
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray addWeakly:object];
	return newArray;
}

- (SPArray *(^ __nonnull)(id object))addWeakly
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object){
			@sp_strongify(self)
			guard(self) return nil;
			[self addWeakly:object];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(id object))addingWeakly
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object){
			@sp_strongify(self)
			guard(self) return nil;
			return [self addedWeakly:object];
		} copy];
	@sp_avoidend(self)
}

- (void) pushForward:(id)object weakly:(BOOL)weakly
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		id objectToAdd = object;
		if([object isKindOfClass:[SPArrayElementWrapper class]])
		{
			objectToAdd = ((SPArrayElementWrapper*)object).value;
		}
		if (weakly)
		{
			__SPArrayElementWrapperWeak *newElement = [[__SPArrayElementWrapperWeak alloc] init];
			newElement.value = objectToAdd;
			newElement.array = self;
			[self->_array insertObject:newElement atIndex:0];
		}
		else
		{
			__SPArrayElementWrapperStrong *newElement = [[__SPArrayElementWrapperStrong alloc] init];
			newElement.value = objectToAdd;
			[self->_array insertObject:newElement atIndex:0];
		}
		self->_sorted = NO;
	});
}

- (SPArray*) pushedForward:(id)object weakly:(BOOL)weakly
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray pushForward:object weakly:weakly];
	return newArray;
}

- (SPArray *(^ __nonnull)(id object, BOOL weakly))pushForward
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object, BOOL weakly){
			@sp_strongify(self)
			guard(self) return nil;
			[self pushForward:object weakly:weakly];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(id object, BOOL weakly))pushingForward
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object, BOOL weakly){
			@sp_strongify(self)
			guard(self) return nil;
			return [self pushedForward:object weakly:weakly];
		} copy];
	@sp_avoidend(self)
}

- (void) insertAtIndex:(NSUInteger) index object:(id)object weakly:(BOOL)weakly
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		id objectToAdd = object;
		if([object isKindOfClass:[SPArrayElementWrapper class]])
		{
			objectToAdd = ((SPArrayElementWrapper*)object).value;
		}
		if (weakly)
		{
			__SPArrayElementWrapperWeak *newElement = [[__SPArrayElementWrapperWeak alloc] init];
			newElement.value = objectToAdd;
			newElement.array = self;
			[self->_array insertObject:objectToAdd atIndex:index];
		}
		else
		{
			__SPArrayElementWrapperStrong *newElement = [[__SPArrayElementWrapperStrong alloc] init];
			newElement.value = objectToAdd;
			[self->_array insertObject:objectToAdd atIndex:index];
		}
		self->_sorted = NO;
	});
}

- (SPArray*) insertedAtIndex:(NSUInteger)index object:(id) object weakly:(BOOL)weakly
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray insertAtIndex:index object:object weakly:weakly];
	return newArray;
}

- (SPArray *(^ __nonnull)(id object, NSUInteger index, BOOL weakly))insertAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object, NSUInteger index, BOOL weakly){
			@sp_strongify(self)
			guard(self) return nil;
			[self insertAtIndex:index object:object weakly:weakly];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(id object, NSUInteger index, BOOL weakly))insertingAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object, NSUInteger index, BOOL weakly){
			@sp_strongify(self)
			guard(self) return nil;
			return [self insertedAtIndex:index object:object weakly:weakly];
		} copy];
	@sp_avoidend(self)
}

- (void) remove:(id)object
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		SPArrayElementWrapper *elementToBeDeleted = nil;
		for(SPArrayElementWrapper *element in self->_array)
		{
			id compareObject = object;
			if([object isKindOfClass:[SPArrayElementWrapper class]])
			{
				compareObject = ((SPArrayElementWrapper*)object).value;
			}
			if(element.value == compareObject)
			{
				elementToBeDeleted = element;
				break;
			}
		}
		if(elementToBeDeleted)
		{
			[self->_array removeObject:elementToBeDeleted];
		}
	});
}

- (SPArray*) removed:(id)object
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray remove:object];
	return newArray;
}

- (SPArray *(^ __nonnull)(id object))remove
{
	@sp_avoidblockretain(self)
		return [^SPArray *(id object){
			@sp_strongify(self)
			guard(self) return nil;
			[self remove:object];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(id object))removing
{
	@sp_avoidblockretain(self)
		return [^SPArray *(id object){
			@sp_strongify(self)
			guard(self) return nil;
			return [self removed:object];
		} copy];
	@sp_avoidend(self)
}

- (void) removeAtIndex:(NSUInteger)index
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		if(index >= self->_array.count)
		{
			NSException *e = [NSException
        						exceptionWithName:@"OutOfBoundException"
							  reason:[NSString stringWithFormat:@"Index: %lud is out of bounds. Count = %lud", (unsigned long)index, (unsigned long)self->_array.count]
        						userInfo:nil];
    		@throw e;
    		return;
		}
		
		[self->_array removeObjectAtIndex:index];
	});
}

- (SPArray*) removedAtIndex:(NSUInteger)index
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	@try
	{
		[newArray removeAtIndex:index];
	}
	@catch (NSException* e)
	{
		NSLog(@"SomePromise SPArray removedAtIndex ERROR:%@. Retur nil as result SPArray", e.reason);
		newArray = nil;
	}
	return newArray;
}

- (SPArray *(^ __nonnull)(NSUInteger index))removeAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object){
			@sp_strongify(self)
			guard(self) return nil;
			@try
			{
				[self remove:object];
			}
			@catch (NSException* e)
			{
				NSLog(@"SomePromise SPArray removedAtIndex ERROR:%@. Retur nil as result SPArray", e.reason);
				return nil;
			}
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(NSUInteger index))removingAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(id object){
			@sp_strongify(self)
			guard(self) return nil;
			return [self removed:object];
		} copy];
	@sp_avoidend(self)
}

- (void) appendArray:(NSArray*)array
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		NSMutableArray *spArray = [NSMutableArray new];
		for(id element in array)
		{
			if([element isKindOfClass:[SPArrayElementWrapper class]])
			{
				[spArray addObject:element];
			}
			else
			{
				SPArrayElementWrapper *wrapper = [[__SPArrayElementWrapperStrong alloc] init];
				wrapper.value = element;
				[spArray addObject:wrapper];
			}
		}
		[self->_array addObjectsFromArray:spArray];
		self->_sorted = NO;
	});
}

- (SPArray*) appendedArray:(NSArray*)array
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray appendArray:array];
	return newArray;
}

- (SPArray *(^ __nonnull)(NSArray *array))appendArray
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			[self appendArray:array];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(NSArray *array))appendingArray
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			return [self appendedArray:array];
		} copy];
	@sp_avoidend(self)
}

- (void) insertArray:(NSArray*)array atIndex:(NSUInteger)index
{
	while(!self.changable)
	{
		[_condition wait];
	}
	if(index >= self->_array.count)
	{
		NSException *e = [NSException
        						exceptionWithName:@"OutOfBoundException"
							  reason:[NSString stringWithFormat:@"Index: %lud is out of bounds. Count = %lud", (unsigned long)index, (unsigned long)self->_array.count]
        						userInfo:nil];
		@throw e;
		return;
	}
	dispatch_sync(_syncQueue, ^{
		NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, array.count)];
		NSMutableArray *spArray = [NSMutableArray new];
		for(id element in array)
		{
			SPArrayElementWrapper *wrapper = [[__SPArrayElementWrapperStrong alloc] init];
			wrapper.value = element;
			[spArray addObject:wrapper];
		}
		[self->_array insertObjects:spArray atIndexes:indexes];
		self->_sorted = NO;
	});
}

- (SPArray*) insertedArray:(NSArray*)array atIndex:(NSUInteger)index
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	@try
	{
		[newArray insertArray:array atIndex:index];
	}
	@catch (NSException* e)
	{
		NSLog(@"SomePromise SPArray insertedArray:atIndex ERROR:%@. Retur nil as result SPArray", e.reason);
		newArray = nil;
	}
	return newArray;
}

- (SPArray *(^ __nonnull)(NSArray *array, NSUInteger index))insertArrayAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			[self appendArray:array];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(NSArray *array, NSUInteger index))insertingArrayAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			return [self appendedArray:array];
		} copy];
	@sp_avoidend(self)
}

- (void) pushArrayForward:(NSArray*) array
{
	[self insertArray:array atIndex:0];
}

- (SPArray*) pushedArrayForward:(NSArray*) array
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray insertedArray:array atIndex:0];
	return newArray;
}

- (SPArray *(^ __nonnull)(NSArray *array))pushArrayForward
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			[self pushArrayForward:array];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(NSArray *array))pushingArrayForward
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			return [self pushedArrayForward:array];
		} copy];
	@sp_avoidend(self)
}

- (void) appendSPArray:(SPArray*)array
{
	while(!self.changable)
	{
		[_condition wait];
	}
	BOOL autoshrinking = self.autoshrink;
	dispatch_sync(_syncQueue, ^{
		for(SPArrayElementWrapper *wrapper in array)
		{
			if(autoshrinking && wrapper.value == nil)
				continue;
			[self->_array addObject:wrapper];
		}
		self->_sorted = NO;
	});
}

- (SPArray*) appendedSPArray:(SPArray*)array
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray appendSPArray:array];
	return newArray;
}

- (SPArray *(^ __nonnull)(SPArray *array))appendSPArray
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			[self appendSPArray:array];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(SPArray *array))appendingSPArray
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			return [self appendedSPArray:array];
		} copy];
	@sp_avoidend(self)
}

- (void) insertSPArray:(SPArray*)array atIndex:(NSUInteger)index
{
	while(!self.changable)
	{
		[_condition wait];
	}
	if(index >= self->_array.count)
	{
		NSException *e = [NSException
        						exceptionWithName:@"OutOfBoundException"
							  reason:[NSString stringWithFormat:@"Index: %lud is out of bounds. Count = %lud", (unsigned long)index, (unsigned long)self->_array.count]
        						userInfo:nil];
		@throw e;
		return;
	}
	BOOL autoshrinking = self.autoshrink;
	dispatch_sync(_syncQueue, ^{
		NSMutableArray *nsArray = [NSMutableArray new];
		for(SPArrayElementWrapper *wrapper in array)
		{
			if(autoshrinking && wrapper.value == nil)
				continue;
			[nsArray addObject:wrapper];
		}
		NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, nsArray.count)];
		[self->_array insertObjects:nsArray atIndexes:indexes];
		self->_sorted = NO;
	});
}

- (SPArray*) insertedSPArray:(SPArray*)array atIndex:(NSUInteger)index
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray insertSPArray:array atIndex:index];
	return newArray;
}

- (SPArray *(^ __nonnull)(SPArray *array, NSUInteger index))insertSPArrayAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArray *array, NSUInteger index){
			@sp_strongify(self)
			guard(self) return nil;
			[self insertSPArray:array atIndex:index];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(SPArray *array, NSUInteger index))insertingSPArrayAtIndex
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArray *array, NSUInteger index){
			@sp_strongify(self)
			guard(self) return nil;
			return [self insertedSPArray:array atIndex:index];
		} copy];
	@sp_avoidend(self)
}

- (void) pushSPArrayForward:(SPArray*) array
{
	[self insertSPArray:array atIndex:0];
}

- (SPArray*) pushedSPArrayForward:(SPArray*) array
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray pushSPArrayForward:array];
	return newArray;
}

- (SPArray *(^ __nonnull)(SPArray *array))pushSPArrayForward
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			[self pushSPArrayForward:array];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *(^ __nonnull)(SPArray *array))pushingSPArrayForward
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArray *array){
			@sp_strongify(self)
			guard(self) return nil;
			return [self pushedSPArrayForward:array];
		} copy];
	@sp_avoidend(self)
}


- (void) sortWithBlock:(SPArrayCompareBlock)block
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		[self->_array sortUsingComparator:block];
		self->_sorted = YES;
	});
}

- (SPArray*) sortedWithBlock:(SPArrayCompareBlock)block
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray sortWithBlock:block];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(SPArrayCompareBlock block))sort
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArrayCompareBlock block){
			@sp_strongify(self)
			guard(self) return nil;
			[self sortWithBlock:block];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *_Nullable(^ __nonnull)(SPArrayCompareBlock block))sorting
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArrayCompareBlock block){
			@sp_strongify(self)
			guard(self) return nil;
			return [self sortedWithBlock:block];
		} copy];
	@sp_avoidend(self)
}

- (void) filter:(SPArrayFilterBlock)block
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		NSMutableArray *arrayToBeDeleted = [NSMutableArray new];
		for(SPArrayElementWrapper *element in self->_array)
		{
			if(!block(element.value))
			{
				[arrayToBeDeleted addObject: element];
			}
		}
		[self->_array removeObjectsInArray:arrayToBeDeleted];
	});
}

- (SPArray*) filtered:(SPArrayFilterBlock)block
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray filter:block];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterBlock block))filter
{
		return [^SPArray*(SPArrayFilterBlock block){
			[self filter:block];
			return self;
		} copy];
}

- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterBlock block))filtering
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArrayFilterBlock block){
			@sp_strongify(self)
			guard(self) return nil;
			return [self filtered:block];
		} copy];
	@sp_avoidend(self)
}

- (void) filterWrappers:(SPArrayFilterWrapperBlock)block
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		NSMutableArray *arrayToBeDeleted = [NSMutableArray new];
		for(SPArrayElementWrapper *element in self->_array)
		{
			if(!block(element))
			{
				[arrayToBeDeleted addObject: element];
			}
		}
		[self->_array removeObjectsInArray:arrayToBeDeleted];
	});
}

- (SPArray*) filteredWrappers:(SPArrayFilterWrapperBlock)block
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray filterWrappers:block];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterWrapperBlock block))filterWrappers
{
		return [^SPArray*(SPArrayFilterWrapperBlock block){
			[self filterWrappers:block];
			return self;
		} copy];

}

- (SPArray *_Nullable(^ __nonnull)(SPArrayFilterWrapperBlock block))filteringWrappers
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArrayFilterBlock block){
			@sp_strongify(self)
			guard(self) return nil;
			return [self filteredWrappers:block];
		} copy];
	@sp_avoidend(self)
}

- (void) map:(SPArrayMapBlock)block
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		for(SPArrayElementWrapper *element in self->_array)
		{
			element.value = block(element.value);
		}
		self->_sorted = NO;
	});
}

- (SPArray*) mapped:(SPArrayMapBlock)block
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray map:block];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(SPArrayMapBlock block))map
{
		return [^SPArray*(SPArrayMapBlock block){

			[self map:block];
			return self;
		} copy];

}

- (SPArray *_Nullable(^ __nonnull)(SPArrayMapBlock block))mapping
{
	@sp_avoidblockretain(self)
		return [^SPArray*(SPArrayMapBlock block){
			@sp_strongify(self)
			guard(self) return nil;
			return [self mapped:block];
		} copy];
	@sp_avoidend(self)
}

- (void) reverse
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		self->_array = [[[self->_array reverseObjectEnumerator] allObjects] mutableCopy];
	});
}
- (SPArray*) reversed
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray reverse];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(void))doRevers
{
		return [^SPArray*(void){

			[self reverse];
			return self;
		} copy];
}

- (SPArray *_Nullable(^ __nonnull)(void))reversing
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void){
			@sp_strongify(self)
			guard(self) return nil;
			return [self reversed];
		} copy];
	@sp_avoidend(self)
}

- (void) swap:(NSUInteger)element1 with:(NSUInteger)element2
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
			if(element1 >= self->_array.count ||element2 >= self->_array.count)
			{
					NSException *e = [NSException
        								exceptionWithName:@"OutOfBoundException"
												   reason:[NSString
										 stringWithFormat:@"Index: %lud or(and) %lud is out of bounds. Count = %lud", (unsigned long)element1, (unsigned long) element2, (unsigned long)self->_array.count]
        										 userInfo:nil];
    				@throw e;
    				return;
			}
			[self->_array exchangeObjectAtIndex:element1 withObjectAtIndex:element2];
			self->_sorted = NO;
	});
}

- (SPArray*) swapped:(NSUInteger)element1 with:(NSUInteger)element2
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray swap:element1 with:element2];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(NSUInteger first,NSUInteger second))swap
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSUInteger first,NSUInteger second){
			@sp_strongify(self)
			guard(self) return nil;
			[self swap:first with:second];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *_Nullable(^ __nonnull)(NSUInteger first, NSUInteger second))swapping
{
	@sp_avoidblockretain(self)
		return [^SPArray*(NSUInteger first,NSUInteger second){
			@sp_strongify(self)
			guard(self) return nil;
			return [self swapped:first with:second];
		} copy];
	@sp_avoidend(self)
}

static void flattenArrayDeeply(NSMutableArray *original, NSMutableArray *result)
{
    for(SPArrayElementWrapper *element in original)
    {
        if(![element.value isKindOfClass:[SPArray class]])
            [result addObject:element];
        else
			flattenArrayDeeply(element.value, result);
    }
}

- (void) flat
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
		NSMutableArray *result = [NSMutableArray new];
		flattenArrayDeeply(self->_array, result);
		self->_array = result;
		self->_sorted = NO;
	});
}

- (SPArray*) flatted
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray flat];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(void))makeFlat
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void){
			@sp_strongify(self)
			guard(self) return nil;
			[self flat];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *_Nullable(^ __nonnull)(void))flatting
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void){
			@sp_strongify(self)
			guard(self) return nil;
			return [self flatted];
		} copy];
	@sp_avoidend(self)
}

- (void) shuffle
{
	while(!self.changable)
	{
		[_condition wait];
	}
	dispatch_sync(_syncQueue, ^{
	    NSUInteger count = [self->_array count];
    	guard (count > 1) else return;
    	for (NSUInteger i = 0; i < count - 1; ++i)
    	{
        	NSInteger remainingCount = count - i;
        	NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        	[self->_array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
        	self->_sorted = NO;
    	}
	});
}

- (NSString*) description
{
	__block NSString *description = nil;
	dispatch_sync(_syncQueue, ^{
		description = self->_array.description;
	});
	return description;
}


- (SPArray*) shuffled
{
	SPArray *newArray = [SPArray arrayWithSPArray:self];
	[newArray shuffle];
	return newArray;
}

- (SPArray *_Nullable(^ __nonnull)(void))doShuffle
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void){
			@sp_strongify(self)
			guard(self) return nil;
			[self flat];
			return self;
		} copy];
	@sp_avoidend(self)
}

- (SPArray *_Nullable(^ __nonnull)(void))shuffling
{
	@sp_avoidblockretain(self)
		return [^SPArray*(void){
			@sp_strongify(self)
			guard(self) return nil;
			return [self flatted];
		} copy];
	@sp_avoidend(self)
}

- (id) reduceResult:(id) result block:(ReduceBlock)block
{
	__block NSMutableArray *array = nil;
	dispatch_sync(_syncQueue, ^{
		array = [self->_array mutableCopy];
	});
	NSUInteger index = 0;
	while(index < array.count)
		result = block(result, index++);
	return result;
}

- (id) getByIndex:(NSUInteger)index
{
	return self[index].value;
}

- (BOOL) has:(id)object
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
	
		for(SPArrayElementWrapper *wrapper in self->_array)
		{
			if(wrapper.value == object)
			{
				result = YES;
				break;
			}
		}
	});
	return result;
}

- (BOOL) isEmpty
{
	return self.count == 0;
}

- (NSDictionary<NSNumber*, SPArrayElementWrapper*>*) enumerated
{
	__block NSMutableDictionary *result = [NSMutableDictionary new];
	dispatch_sync(_syncQueue, ^{
		for(int i = 0; i < self->_array.count; ++i)
		{
			result[@(i)] = self->_array[i];
		}
	});
	
	return result;
}

- (id _Nullable) randomElement
{
	__block id result = nil;
	dispatch_sync(_syncQueue, ^{
	
		NSUInteger randomIndex = arc4random_uniform((u_int32_t )self->_array.count);
		result = self->_array[randomIndex].value;
	});
	return result;
}

- (NSArray*) toArray
{
	__block NSMutableArray *result = [NSMutableArray new];
	dispatch_sync(_syncQueue, ^{
		for(SPArrayElementWrapper *wrapper in self->_array)
		{
			if(wrapper.value)
			{
				[result addObject:wrapper.value];
			}
		}
	});
	return result;
}
- (NSArray*) toArrayWithWrappers
{
	__block NSArray *result = nil;
	dispatch_sync(_syncQueue, ^{
		result = [self->_array copy];
	});
	return result;
}

- (id _Nullable) last
{
	__block id result = nil;
	dispatch_sync(_syncQueue, ^{
		result = self->_array.lastObject.value;
	});
	return result;
}

- (id _Nullable) first
{
	__block id result = nil;
	dispatch_sync(_syncQueue, ^{
		result = self->_array.firstObject.value;
	});
	return result;
}

- (SPArray*) range:(NSRange)range
{
	__block SPArray *result = nil;
	dispatch_sync(_syncQueue, ^{
		result = [SPArray fromArray:[self->_array subarrayWithRange:range]];
	});
	return result;
}

- (Class) typeForIndex:(NSUInteger)index
{
	__block Class result = nil;
	dispatch_sync(_syncQueue, ^{
		result = [self->_array[index].value class];
	});
	return result;
}

- (BOOL) isElementWeaklyStoredAtIndex:(NSUInteger)index
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		result = [self->_array[index] weakly];
	});
	return result;
}

- (BOOL) sorted
{
	__block BOOL sorted = NO;
	dispatch_sync(_syncQueue, ^{
		sorted = self->_sorted;
	});
	return sorted;
}

@end
