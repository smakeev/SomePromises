//
//  SomePromiseEvents.m
//  SomePromises
//
//  Created by Sergey Makeev on 06/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseEvents.h"
#import "SomePromiseUtils.h"
#import "SomePromiseThread.h"
#import "SomePromiseTypes.h"

#import <objc/runtime.h>

static char const * const ObjectTagKey = "SPDestroyWatcherTagKey";

@interface __SPDestroyWatcher : NSObject
{
	NSMutableArray<SPPair<NSDictionary*, SPEventListener> *> *_listeners;
}

@end

@implementation __SPDestroyWatcher

- (instancetype) initWitDictionary:(NSDictionary*)params andListener:(SPEventListener) listener
{
	self = [super init];
	
	if(self)
	{
		@synchronized(self)
		{
			_listeners = [NSMutableArray new];
			[_listeners addObject:[SPPair pairWithLeft:params right:listener]];
		}
	}
	
	return self;
}

- (void) addListener:(SPEventListener)listener withParameters:(NSDictionary*)msg
{
	@synchronized(self)
	{
		[_listeners addObject:[SPPair pairWithLeft:msg right:listener]];
	}
}

- (void) dealloc
{
	NSArray<SPPair<NSDictionary*, SPEventListener> *> *listeners = nil;
	@synchronized(self)
	{
		listeners = [_listeners copy];
	}
	
	for (SPPair<NSDictionary*, SPEventListener> *pair in listeners)
	{
		pair.right(pair.left);
	}
}

@end

@interface __SomePromiseEventItem : NSObject

@property(nonatomic, copy) SPEventListener listener;
@property(nonatomic) BOOL isOnce;
@property(nonatomic) dispatch_queue_t queue;
@property(nonatomic) SomePromiseThread *thread;
@property(nonatomic) BOOL *finishedCondition;
@property(nonatomic) NSCondition *condition;
@property(nonatomic) NSDictionary *msg;

@end

@implementation __SomePromiseEventItem
@end

@class __SomePromiseEvents;
static __SomePromiseEvents *_instance = nil;

@interface __SomePromiseEvents : NSObject
{
	SPMapTable<id, NSDictionary<NSString*, SPMapTable<id, NSArray<__SomePromiseEventItem*> *> *>*> *_store;
	dispatch_queue_t _syncQueue;
	dispatch_queue_t _defaultQueue;
}
@end

@implementation __SomePromiseEvents
+ (instancetype) instance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
				  {
					  _instance = [[__SomePromiseEvents alloc] init];
				  });
	return _instance;
}

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		_store = [SPMapTable new];
		_syncQueue = dispatch_queue_create("__SomePromiseEventsSyncStore_queue", DISPATCH_QUEUE_SERIAL);
		_defaultQueue = dispatch_queue_create("__SomePromiseEventsDefault_queue", DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

- (void) runEvent:(id)target event:(NSString*)event message:(NSDictionary*)message
{
	__strong id strongTarget = target;
	//NSLog(@"!@!@ %@", event);
	dispatch_sync(_syncQueue, ^{
		
		NSMutableDictionary *dictionary = (NSMutableDictionary*)[self->_store objectForKey:strongTarget];
		guard (dictionary) else {return;} //there are no subscribers
		SPMapTable *eventMap = dictionary[event];
		guard (eventMap) else {return;} //there are no subscribers
		
		NSEnumerator *enumerator = [eventMap keyEnumerator];
		__strong id value = nil;
		while ((value = [enumerator nextObject]))
		{
			NSMutableArray *itemsToBeDeleted = [NSMutableArray new];
			NSMutableArray *array = [eventMap objectForKey:value];
			for (__SomePromiseEventItem *item in array)
			{
				if(item.isOnce){
					[itemsToBeDeleted addObject:item];
				}
				
				if(item.thread)
				{
					[item.thread performBlock:^(){
						item.listener(message);
					}];
				}
				else if(item.queue)
				{
					dispatch_async(item.queue, ^{
						item.listener(message);
					});
				}
				item.msg = message;
				
				if(item.condition && item.finishedCondition)
				{
					*(item.finishedCondition) = YES;
					[item.condition signal];
				}
			}
			
			if([itemsToBeDeleted count])
			{
				[array removeObjectsInArray:itemsToBeDeleted];
			}
		}
	});
}

- (void) setEvent:(NSString*)event from:(id)target beListeningBy:(id)listener once:(BOOL)once onThread:(SomePromiseThread*)thread onQueue:(dispatch_queue_t)queue withHandler:(SPEventListener)handler
{
	__strong id strongTarget = target;
	__strong id strongListener = listener;
	dispatch_sync(_syncQueue, ^{
		NSMutableDictionary *dictionary = (NSMutableDictionary*)[self->_store objectForKey:strongTarget];
		if(dictionary == nil)
		{
			dictionary = [NSMutableDictionary new];
			[self->_store setObject:dictionary forKey:strongTarget];
		}
		
		SPMapTable *eventMap = dictionary[event];
		
		if(eventMap == nil)
		{
			eventMap = [SPMapTable new];
			dictionary[event] = eventMap;
		}
		
		NSMutableArray *items = [eventMap objectForKey:strongListener];
		if(items == nil)
		{
			items = [NSMutableArray new];
			[eventMap setObject:items forKey:strongListener];
		}
		
		//create item
		__SomePromiseEventItem *item = [[__SomePromiseEventItem alloc] init];
		item.listener = handler;
		item.isOnce = once;
		if(queue)
		{
			item.queue = queue;
		}
		else if(thread)
		{
			item.thread = thread;
		}
		else
		{
			item.queue = self->_defaultQueue;
		}
		
		[items addObject:item];
	});
}

- (void) unsubscribe:(id)subscriber forEvent:(NSString*)event from:(id)target
{
	__strong id strongTarget = target;
	__strong id strongListener = subscriber;
	dispatch_sync(_syncQueue, ^{
		NSMutableDictionary *dictionary = (NSMutableDictionary*)[self->_store objectForKey:strongTarget];
		guard(dictionary) else {return;}
		SPMapTable *eventMap = dictionary[event];
		guard(eventMap) else {return;}
		[eventMap removeObjectForKey:strongListener];
	});
}

- (void) wait:(id)target listenedBy:(id)subscriber forEvent:(NSString*)event listener:(SPEventListener) listener
{
	guard(listener) else {return;}
	__strong id strongTarget = target;
	__strong id strongListener = subscriber;
	NSCondition *condition = [[NSCondition alloc] init];
	__SomePromiseEventItem *item = [[__SomePromiseEventItem alloc] init];
	__block BOOL finished = NO;
	dispatch_sync(_syncQueue, ^{
		NSMutableDictionary *dictionary = (NSMutableDictionary*)[self->_store objectForKey:strongTarget];
		if(dictionary == nil)
		{
			dictionary = [NSMutableDictionary new];
			[self->_store setObject:dictionary forKey:strongTarget];
		}
		
		SPMapTable *eventMap = dictionary[event];
		
		if(eventMap == nil)
		{
			eventMap = [SPMapTable new];
			dictionary[event] = eventMap;
		}
		
		NSMutableArray *items = [eventMap objectForKey:strongListener];
		if(items == nil)
		{
			items = [NSMutableArray new];
			[eventMap setObject:items forKey:strongListener];
		}
		
		//create item
		item.listener = nil;
		//item.listener = listener;
		item.isOnce = YES;
		
		item.finishedCondition = &finished;
		item.condition = condition;
		[items addObject:item];
	});
	
	while(!finished)
	{
		[condition wait];
	}
	
	listener(item.msg);
}

@end

static void __sp_trigger(id target, NSString *event, NSDictionary *message)
{
	[[__SomePromiseEvents instance] runEvent:target event:event message:message];
}

static void __sp_wait(id target, id subscriber, NSString *event, SPEventListener listener)
{
	[[__SomePromiseEvents instance] wait:target listenedBy:subscriber forEvent:event listener:listener];
}

static void __sp_on(id target, NSString *event, id subscriber, SPEventListener listener)
{
	[[__SomePromiseEvents instance] setEvent:event
										from:target
							   beListeningBy:subscriber
										once:NO
									onThread:nil
									 onQueue:nil
								 withHandler:listener];
}

static void __sp_onQueue(id target, NSString *event, dispatch_queue_t queue, id subscriber, SPEventListener listener)
{
	[[__SomePromiseEvents instance] setEvent:event
										from:target
							   beListeningBy:subscriber
										once:NO
									onThread:nil
									 onQueue:queue
								 withHandler:listener];
	
}

static void __sp_onceQueue(id target, NSString *event, dispatch_queue_t queue, id subscriber, SPEventListener listener)
{
	[[__SomePromiseEvents instance] setEvent:event
										from:target
							   beListeningBy:subscriber
										once:YES
									onThread:nil
									 onQueue:queue
								 withHandler:listener];
	
}

static void __sp_onThread(id target, NSString *event, SomePromiseThread *thread, id subscriber, SPEventListener listener)
{
	[[__SomePromiseEvents instance] setEvent:event
										from:target
							   beListeningBy:subscriber
										once:NO
									onThread:thread
									 onQueue:nil
								 withHandler:listener];
	
}

static void __sp_onceThread(id target, NSString *event, SomePromiseThread *thread, id subscriber, SPEventListener listener)
{
	[[__SomePromiseEvents instance] setEvent:event
										from:target
							   beListeningBy:subscriber
										once:YES
									onThread:thread
									 onQueue:nil
								 withHandler:listener];
	
}

static void __sp_once(id target, NSString *event, id subscriber, SPEventListener listener)
{
	[[__SomePromiseEvents instance] setEvent:event
										from:target
							   beListeningBy:subscriber
										once:YES
									onThread:nil
									 onQueue:nil
								 withHandler:listener];
	
}

static void __sp_off(id target, NSString *event, id subscriber)
{
	[[__SomePromiseEvents instance] unsubscribe:subscriber forEvent:event from:target];
}

static void __sp_addOnDestroy(id target, SPEventListener listener, NSDictionary *msg)
{
	__SPDestroyWatcher *watcher = objc_getAssociatedObject(target, ObjectTagKey);
	if(watcher == nil)
	{
		watcher = [[__SPDestroyWatcher alloc] initWitDictionary:msg andListener:listener];
		objc_setAssociatedObject(target, ObjectTagKey, watcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	else
	{
		[watcher addListener:listener withParameters:msg];
	}
}

@implementation NSObject (SomePromiseEvents)
- (void)spOn:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_on(self, eventName, target, listener);
}

- (void)spOnce:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_once(self, eventName, target, listener);
}

- (void)spOn:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onQueue(self, eventName, queue, target, listener);
}

- (void)spOnce:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onceQueue(self, eventName, queue, target, listener);
}

- (void)spOn:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onThread(self, eventName, thread, target, listener);
}

- (void)spOnce:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onceThread(self, eventName, thread, target, listener);
}

- (void)spOff:(NSString*_Nonnull) eventName target:(id _Nonnull)target
{
	__sp_off(self, eventName, target);
}

- (void)waitForEvent:(NSString*_Nonnull) eventName  by:(id)eventSource listener:(SPEventListener _Nonnull)listener
{
	__sp_wait(self, eventSource, eventName, listener);
}

- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener
{
	[other spOn:eventName target:self listener:listener];
}

- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener
{
	[other spOnce:eventName target:self listener:listener];
}

- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener
{
	[other spOn:eventName onQueue:queue target:self listener:listener];
}

- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener
{
	[other spOnce:eventName onQueue:queue target:self listener:listener];
}

- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener
{
	[other spOn:eventName onThread:thread target:self listener:listener];
}

- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener
{
	[other spOnce:eventName onThread:thread target:self listener:listener];
}

- (void)spStopListening:(id _Nonnull)other event:(NSString*_Nonnull) eventName
{
	[other spOff:eventName target:self];
}

- (void)waitForEvent:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener
{
	[self waitForEvent:eventName by:other listener:listener];
}

- (void)spTrigger:(NSString*_Nonnull) eventName message:(NSDictionary *_Nullable)msg
{
	__sp_trigger(self, eventName, msg);
}

- (void)spAddDestroyListener:(SPEventListener _Nonnull)listener message:(NSDictionary *)msg
{
	__sp_addOnDestroy(self, listener, msg);
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOn
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOn:eventName target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnce
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOnce:eventName target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnOnQueue
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, dispatch_queue_t queue, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOn:name onQueue:queue target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnceOnQueue
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, dispatch_queue_t queue, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOnce:name onQueue:queue target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnOnThread
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, SomePromiseThread *thread, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOn:name onThread:thread target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnceOnThread
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, SomePromiseThread *thread, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOnce:name onThread:thread target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spOff
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id target){
		@sp_strongify(self)
		[self spOff:eventName target:target];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPEventListener _Nonnull))waitForEvent
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id eventSource,SPEventListener listener){
		@sp_strongify(self)
		[self waitForEvent:eventName by:eventSource listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spListenTo
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SPEventListener listener){
		@sp_strongify(self)
		[self spListenTo:other event:eventName listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spOnceListenTo
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SPEventListener listener){
		@sp_strongify(self)
		[self spOnceListenTo:other event:eventName listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spListenToOnQueue
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, dispatch_queue_t queue, SPEventListener listener){
		@sp_strongify(self)
		[self spListenTo:other event:eventName onQueue:queue listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spOnceListenToOnQueue
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, dispatch_queue_t queue, SPEventListener listener){
		@sp_strongify(self)
		[self spOnceListenTo:other event:eventName onQueue:queue listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spListenToOnThread
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SomePromiseThread *thread, SPEventListener listener){
		@sp_strongify(self)
		[self spListenTo:other event:eventName onThread:thread listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spOnceListenToOnThread
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SomePromiseThread *thread, SPEventListener listener){
		@sp_strongify(self)
		[self spOnceListenTo:other event:eventName onThread:thread listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull))spStopListening
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName){
		@sp_strongify(self)
		[self spStopListening:other event:eventName];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))waitForEventFromOther
{
	@sp_avoidblockretain(self)
	return [^(id other, NSString *eventName, SPEventListener listener){
		@sp_strongify(self)
		[self waitForEvent:other event:eventName listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, NSDictionary *_Nullable))spTrigger
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, NSDictionary *msg){
		@sp_strongify(self)
		[self spTrigger:eventName message:msg];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSDictionary *_Nullable, SPEventListener _Nonnull))spDestroyListener
{
	@sp_avoidblockretain(self)
	return [^(NSDictionary *msg, SPEventListener listener){
		@sp_strongify(self)
		[self spAddDestroyListener:listener message:msg];
	} copy];
	@sp_avoidend(self)
}

@end


@implementation NSProxy (SomePromiseEvents)

- (void)spOn:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_on(self, eventName, target, listener);
}

- (void)spOnce:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_once(self, eventName, target, listener);
}

- (void)spOn:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onQueue(self, eventName, queue, target, listener);
}

- (void)spOnce:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onceQueue(self, eventName, queue, target, listener);
}

- (void)spOn:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onThread(self, eventName, thread, target, listener);
}

- (void)spOnce:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener
{
	__sp_onceThread(self, eventName, thread, target, listener);
}

- (void)spOff:(NSString*_Nonnull) eventName target:(id _Nonnull)target
{
	__sp_off(self, eventName, target);
}

- (void)waitForEvent:(NSString*_Nonnull) eventName by:(id)eventSource listener:(SPEventListener _Nonnull)listener
{
	__sp_wait(self, eventSource, eventName, listener);
}

- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener
{
	[other spOn:eventName target:self listener:listener];
}

- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener
{
	[other spOnce:eventName target:self listener:listener];
}

- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener
{
	[other spOn:eventName onQueue:queue target:self listener:listener];
}

- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener
{
	[other spOnce:eventName onQueue:queue target:self listener:listener];
}

- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener
{
	[other spOn:eventName onThread:thread target:self listener:listener];
}

- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener
{
	[other spOnce:eventName onThread:thread target:self listener:listener];
}

- (void)spStopListening:(id _Nonnull)other event:(NSString*_Nonnull) eventName
{
	[other spOff:eventName target:self];
}

- (void)waitForEvent:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener
{
	[self waitForEvent:eventName by:other listener:listener];
}

- (void)spTrigger:(NSString*_Nonnull) eventName message:(NSDictionary *_Nullable)msg
{
	__sp_trigger(self, eventName, msg);
}

- (void)spAddDestroyListener:(SPEventListener _Nonnull)listener message:(NSDictionary *_Nullable)msg
{
	__sp_addOnDestroy(self, listener, msg);
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOn
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOn:eventName target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnce
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOnce:eventName target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnOnQueue
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, dispatch_queue_t queue, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOn:name onQueue:queue target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnceOnQueue
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, dispatch_queue_t queue, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOnce:name onQueue:queue target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnOnThread
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, SomePromiseThread *thread, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOn:name onThread:thread target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnceOnThread
{
	@sp_avoidblockretain(self)
	return [^(NSString *name, SomePromiseThread *thread, id target, SPEventListener listener){
		@sp_strongify(self)
		[self spOnce:name onThread:thread target:target listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spOff
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id target){
		@sp_strongify(self)
		[self spOff:eventName target:target];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPEventListener _Nonnull))waitForEvent
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, id eventSource,SPEventListener listener){
		@sp_strongify(self)
		[self waitForEvent:eventName by:eventSource listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spListenTo
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SPEventListener listener){
		@sp_strongify(self)
		[self spListenTo:other event:eventName listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spOnceListenTo
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SPEventListener listener){
		@sp_strongify(self)
		[self spOnceListenTo:other event:eventName listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spListenToOnQueue
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, dispatch_queue_t queue, SPEventListener listener){
		@sp_strongify(self)
		[self spListenTo:other event:eventName onQueue:queue listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spOnceListenToOnQueue
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, dispatch_queue_t queue, SPEventListener listener){
		@sp_strongify(self)
		[self spOnceListenTo:other event:eventName onQueue:queue listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spListenToOnThread
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SomePromiseThread *thread, SPEventListener listener){
		@sp_strongify(self)
		[self spListenTo:other event:eventName onThread:thread listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spOnceListenToOnThread
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName, SomePromiseThread *thread, SPEventListener listener){
		@sp_strongify(self)
		[self spOnceListenTo:other event:eventName onThread:thread listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull))spStopListening
{
	@sp_avoidblockretain(self)
	return [^(id other,NSString *eventName){
		@sp_strongify(self)
		[self spStopListening:other event:eventName];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))waitForEventFromOther
{
	@sp_avoidblockretain(self)
	return [^(id other, NSString *eventName, SPEventListener listener){
		@sp_strongify(self)
		[self waitForEvent:other event:eventName listener:listener];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSString *_Nonnull, NSDictionary *_Nullable))spTrigger
{
	@sp_avoidblockretain(self)
	return [^(NSString *eventName, NSDictionary *msg){
		@sp_strongify(self)
		[self spTrigger:eventName message:msg];
	} copy];
	@sp_avoidend(self)
}

- (void (^ __nonnull)(NSDictionary *_Nullable, SPEventListener _Nonnull))spDestroyListener
{
	@sp_avoidblockretain(self)
	return [^(NSDictionary *msg, SPEventListener listener){
		@sp_strongify(self)
		[self spAddDestroyListener:listener message:msg];
	} copy];
	@sp_avoidend(self)
}

@end

#pragma mark -
#pragma mark SPEventExpector

@interface SPEventExpector ()
{
	__strong SPEventExpector *_agent;
	NSTimer *_timer;
	NSString *_eventName;
	BOOL _active;
	BOOL _triggerable;
	__weak id _target;
}

@property (nonatomic, copy)SPEventHandler handler;
@property (nonatomic, copy)SPTimeoutHandler timeout;
@property (nonatomic, copy)SPShouldAccept accept;

- (instancetype) initWithEvent:(NSString*)event target:(id)target  interval:(NSTimeInterval)interval accept:(SPShouldAccept)accept onReceived:(SPEventHandler)handler onTimeout:(SPTimeoutHandler)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread destroyMessage:(NSDictionary*)destroyMessage;

@end

@implementation SPEventExpector
+ (instancetype) waitForNSNotificationWithName:(NSString*) eventName forTimeInterval:(NSTimeInterval)interval accept:(SPShouldAccept)accept onReceived:(SPEventHandler)handler onTimeout:(SPTimeoutHandler)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread
{
	return [[SPEventExpector alloc] initWithEvent:eventName target:nil interval:interval accept:accept onReceived:handler onTimeout:timeoutHandler waitOnThread:thread destroyMessage:nil];
}

+ (instancetype) waitForTriggeredEventForTimeInterval:(NSTimeInterval)interval accept:(SPShouldAccept)accept onReceived:(SPEventHandler)handler onTimeout:(SPTimeoutHandler)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread
{
	return [[SPEventExpector alloc] initWithEvent:nil target:nil interval:interval accept:accept onReceived:handler onTimeout:timeoutHandler waitOnThread:thread destroyMessage:nil];
}

+ (instancetype) waitForEvent:(NSString*)eventName fromTarget:(id)target ForTimeInterval:(NSTimeInterval)interval accept:(SPShouldAccept _Nullable)accept onReceived:(SPEventHandler _Nullable)handler onTimeout:(SPTimeoutHandler _Nullable)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread
{
    return [[SPEventExpector alloc] initWithEvent:eventName target:target interval:interval accept:accept onReceived:handler onTimeout:timeoutHandler waitOnThread:thread destroyMessage:nil];
}

+ (instancetype) waitForDestroyOfObject:(id)target forTimeInterval:(NSTimeInterval)interval destroyMessage:(NSDictionary*)msg onReceived:(SPEventHandler _Nullable)handler onTimeout:(SPTimeoutHandler _Nullable)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread
{
	return [[SPEventExpector alloc] initWithEvent:nil target:target interval:interval accept:nil onReceived:handler onTimeout:timeoutHandler waitOnThread:thread destroyMessage:msg];
}


- (instancetype) initWithEvent:(NSString*)event target:(id)target interval:(NSTimeInterval)interval accept:(SPShouldAccept)accept onReceived:(SPEventHandler)handler onTimeout:(SPTimeoutHandler)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread destroyMessage:(NSDictionary*)destroyMessage
{
	self = [super init];
	
	if(self)
	{
		_active = YES;
		self.handler = handler;
		self.timeout = timeoutHandler;
		self.accept = accept;
		_agent = self;
		__weak SPEventExpector *weakSelf = self;
		_eventName = [event copy];
		if(event && !target)
		{
			[[NSNotificationCenter defaultCenter] addObserverForName:event object:nil queue:nil usingBlock:^(NSNotification *note)
			 {
				 __strong SPEventExpector *strongSelf = weakSelf;
				 guard(strongSelf) else {return;}
				 [strongSelf trigger:note.userInfo];
			 }];
		}
		else if(event && target)
		{
			_target = target;
			//place onDestroy observer to be notified if target has been destroyed before event came.
			((NSObject*)_target).spDestroyListener(nil, ^(NSDictionary *msg){
				__strong SPEventExpector *strongSelf = weakSelf;
				guard(strongSelf) else {return;}
				if(strongSelf.timeout)
					strongSelf.timeout();
				strongSelf->_active = NO;
			});
			
			((NSObject*)_target).spOn(_eventName, self, ^(NSDictionary *msg){
				__strong SPEventExpector *strongSelf = weakSelf;
				guard(strongSelf) else {return;}
				strongSelf->_triggerable = YES;
				[strongSelf trigger:msg];
			});
		}
		else if(!event && target) //waiter for target destroy
		{
			_target = target;
			((NSObject*)_target).spDestroyListener(destroyMessage, ^(NSDictionary *msg){
				__strong SPEventExpector *strongSelf = weakSelf;
				guard(strongSelf) else {return;}
				strongSelf->_triggerable = YES;
				[strongSelf trigger:msg];
			});
		}
		else
		{
		   _triggerable = YES;
		}
		
		if(interval != 0)
		{
		    void (^timerBlock)(NSTimer *) = ^(NSTimer *timer){
				   __strong SPEventExpector *strongSelf = weakSelf;
				   guard(strongSelf) else {return;}
				   if(strongSelf.timeout)
					strongSelf.timeout();
				   [[NSNotificationCenter defaultCenter] removeObserver:strongSelf];
				   strongSelf->_agent = nil;
				   strongSelf->_active = NO;
			};
		
		    if(thread == nil)
		    {
				_timer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:NO block:^(NSTimer *timer)
				{
					timerBlock(timer);
			   	}];
			}
			else
			{
				_timer = [thread scheduledTimerWithTimeInterval:interval repeats:NO block:^(NSTimer *timer)
				{
					timerBlock(timer);
				}];
			}
		}
	}
	return self;
}

- (void) trigger:(NSDictionary*)msg
{
    guard(_triggerable) else {return;}
	guard(_active) else { return; }
	if(self.accept)
	{
		guard(self.accept(msg)) else {return;}
	}
	[self->_timer invalidate];
	if(self.handler)
	{
		self.handler(msg);
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_active = NO;
	_triggerable = NO;
	self->_agent = nil;
	if(_target)
	{
	   ((NSObject*)_target).spOff(_eventName, self);
	}
}

- (BOOL) isActive
{
	return _active;
}

- (void) reject
{
	_agent = nil;
	_active = NO;
	_triggerable = NO;
	if(self.onReject)
	{
		self.onReject();
	}
	// in case there are other strong references
	if(_target)
	{
	   ((NSObject*)_target).spOff(_eventName, self);
	}
	[_timer invalidate];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) dealloc
{
	if(_target)
	{
	   ((NSObject*)_target).spOff(_eventName, self);
	}
	[_timer invalidate];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
   NSLog(@"Event expector Deallocated");
#endif
}

@end
