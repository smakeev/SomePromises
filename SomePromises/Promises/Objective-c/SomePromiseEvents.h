//
//  SomePromiseEvents.h
//  SomePromises
//
//  Created by Sergey Makeev on 06/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

//Each object instance (of any type) can create an event and can listen to events from other objects.

typedef void (^ SPEventListener)(NSDictionary *_Nullable);
@class SomePromiseThread;
@interface NSObject (SomePromiseEvents)
//start listening event with eventName from target using block listener.
- (void)spOn:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;

//listen to event with eventName from target using listener block just once.
- (void)spOnce:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;

//start listening event with eventName from target using block listener on queue.
- (void)spOn:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;

//listen to event with eventName from target using listener block on queue just once.
- (void)spOnce:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;

//start listening event with eventName from target using block listener on thread.
- (void)spOn:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;

//listen to event with eventName from target using listener block on thread just once.
- (void)spOnce:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;

//stop listening eventWith name from target.
- (void)spOff:(NSString*_Nonnull) eventName target:(id _Nonnull)target;

//stop current thread until get event eith eventName from eventSource with listener block.
//If eventSource destroy it does not unlock the thread.
- (void)waitForEvent:(NSString*_Nonnull) eventName by:(id)eventSource listener:(SPEventListener _Nonnull)listener;

//start listening to other instance for event with eventName with listener block.
- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener;

//start listening to other instance for event with eventName with listener block just once.
- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener;

//start listening to other instance for event with eventName with listener block on queue.
- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener;

//start listening to other instance for event with eventName with listener block just once on queue.
- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener;

//start listening to other instance for event with eventName with listener block on thread.
- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener;

//start listening to other instance for event with eventName with listener block just once on thread.
- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener;

//stop listening to other instance for event with eventName.
- (void)spStopListening:(id _Nonnull)other event:(NSString*_Nonnull) eventName;

//lock current thread until other instance send event with eventName and handle it in listener block.
- (void)waitForEvent:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener;

//send event with eventName and message (could be any NSDictionary or nil).
- (void)spTrigger:(NSString*_Nonnull) eventName message:(NSDictionary *_Nullable)msg;

//Add destroy listener to current instance
//When instance will be in deallocating process all it's destroy listeners will be called.
//For destroy event owner(lifetime provider) is the object itself.
//You may provide a message here, this message will be just resend to the block when it will be called.
//Usually it will be nil.
- (void)spAddDestroyListener:(SPEventListener _Nonnull)listener message:(NSDictionary *_Nullable)msg;

//The same methods. But in variant of returning blocks to provide this methods.
//Just to make possible to call them like so: instance.spOnce(@"hello event", otherInstance, ^(NSDictionary *message){ ... });
//or this block could be stored and be called later.
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOn;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnce;
- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnOnQueue;
- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnceOnQueue;
- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnOnThread;
- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnceOnThread;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spOff;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPEventListener _Nonnull))waitForEvent;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spListenTo;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spOnceListenTo;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spListenToOnQueue;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spOnceListenToOnQueue;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spListenToOnThread;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spOnceListenToOnThread;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull))spStopListening;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))waitForEventFromOther;
- (void (^ __nonnull)(NSString *_Nonnull, NSDictionary *_Nullable))spTrigger;
- (void (^ __nonnull)(NSDictionary *_Nullable msg, SPEventListener _Nonnull))spDestroyListener;

@end

@interface NSProxy (SomePromiseEvents)
- (void)spOn:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;
- (void)spOnce:(NSString*_Nonnull) eventName target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;
- (void)spOn:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;
- (void)spOnce:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;
- (void)spOn:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;
- (void)spOnce:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread target:(id _Nonnull)target listener:(SPEventListener _Nonnull)listener;
- (void)spOff:(NSString*_Nonnull) eventName target:(id _Nonnull)target;
- (void)waitForEvent:(NSString*_Nonnull) eventName by:(id)eventSource listener:(SPEventListener _Nonnull)listener;
- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener;
- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener;
- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener;
- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onQueue:(dispatch_queue_t)queue listener:(SPEventListener _Nonnull)listener;
- (void)spListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener;
- (void)spOnceListenTo:(id _Nonnull)other event:(NSString*_Nonnull) eventName onThread:(SomePromiseThread*)thread listener:(SPEventListener _Nonnull)listener;
- (void)spStopListening:(id _Nonnull)other event:(NSString*_Nonnull) eventName;
- (void)waitForEvent:(id _Nonnull)other event:(NSString*_Nonnull) eventName listener:(SPEventListener _Nonnull)listener;
- (void)spTrigger:(NSString*_Nonnull) eventName message:(NSDictionary *_Nullable)msg;
- (void)spAddDestroyListener:(SPEventListener _Nonnull)listener message:(NSDictionary *_Nullable)msg;

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOn;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnce;
- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnOnQueue;
- (void (^ __nonnull)(NSString *_Nonnull, dispatch_queue_t, id _Nullable, SPEventListener _Nonnull))spOnceOnQueue;
- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnOnThread;
- (void (^ __nonnull)(NSString *_Nonnull, SomePromiseThread *_Nonnull, id _Nullable, SPEventListener _Nonnull))spOnceOnThread;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spOff;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPEventListener _Nonnull))waitForEvent;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spListenTo;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))spOnceListenTo;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spListenToOnQueue;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, dispatch_queue_t, SPEventListener _Nonnull))spOnceListenToOnQueue;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spListenToOnThread;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SomePromiseThread *_Nonnull, SPEventListener _Nonnull))spOnceListenToOnThread;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull))spStopListening;
- (void (^ __nonnull)(id _Nonnull, NSString *_Nonnull, SPEventListener _Nonnull))waitForEventFromOther;
- (void (^ __nonnull)(NSString *_Nonnull, NSDictionary *_Nullable))spTrigger;
- (void (^ __nonnull)(NSDictionary *_Nullable msg, SPEventListener _Nonnull))spDestroyListener;

@end

typedef void (^SPEventHandler)(NSDictionary*_Nullable);
typedef BOOL (^SPShouldAccept)(NSDictionary*_Nullable);
typedef void (^SPTimeoutHandler)(void);
@interface SPEventExpector: NSObject

@property(nonatomic, copy) void(^onReject)(void);

//Pass 0 as time interval to have unlimited waiting time.
+ (instancetype) waitForNSNotificationWithName:(NSString *_Nonnull) eventName forTimeInterval:(NSTimeInterval)interval accept:(SPShouldAccept _Nullable)accept onReceived:(SPEventHandler _Nullable)handler onTimeout:(SPTimeoutHandler _Nullable)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread;
+ (instancetype) waitForTriggeredEventForTimeInterval:(NSTimeInterval)interval accept:(SPShouldAccept _Nullable)accept onReceived:(SPEventHandler _Nullable)handler onTimeout:(SPTimeoutHandler _Nullable)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread;
+ (instancetype) waitForEvent:(NSString*)eventName fromTarget:(id)target ForTimeInterval:(NSTimeInterval)interval accept:(SPShouldAccept _Nullable)accept onReceived:(SPEventHandler _Nullable)handler onTimeout:(SPTimeoutHandler _Nullable)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread;
+ (instancetype) waitForDestroyOfObject:(id)target forTimeInterval:(NSTimeInterval)interval destroyMessage:(NSDictionary*)msg onReceived:(SPEventHandler _Nullable)handler onTimeout:(SPTimeoutHandler _Nullable)timeoutHandler waitOnThread:(SomePromiseThread *_Nullable)thread;

- (void) trigger:(NSDictionary*)msg;
- (void) reject;
- (BOOL) isActive;
@end
