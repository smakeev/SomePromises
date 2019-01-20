//
//  SomePromiseDataStream.h
//  SomePromises
//
//  Created by Sergey Makeev on 04/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SomePromiseUtils.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// @sp_observe(object, key)
// will create a SomePromiseDataStream observing key of object
// using KVO.
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observe(object, key) \
		"should be called with @" @"".createSPStreamForObject([NSString stringWithUTF8String:#key], object, 0)

#define sp_observeOnce(object, key) \
		"should be called with @" @"".createSPStreamForObject([NSString stringWithUTF8String:#key], object, 1)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeTextField(textField)
//	will create a SomePromiseDataStream observing textField text
//	will be updated on any kind of text change (by user or programmatically done).
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeTextField(textField) \
		"should be called with @" @"".createSPStream(@"path", 0).addTextField(textField)

#define sp_observeTextFieldOnce(textField) \
		"should be called with @" @"".createSPStream(@"path", 1).addTextField(textField)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeTextView(textView)
//	will create a SomePromiseDataStream observing textView text
//	will be updated on any kind of text change (by user or programmatically done).
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeTextView(textView) \
		"should be called with @" @"".createSPStream(@"path", 0).addTextView(textView)

#define sp_observeTextViewOnce(textView) \
		"should be called with @" @"".createSPStream(@"path", 1).addTextView(textView)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeSwitch(switch)
//	will create a SomePromiseDataStream observing switch value
//	will be updated on any kind of value change (by user or programmatically done).
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeSwitch(switch) \
		"should be called with @" @"".createSPStream(@"path", 0).addSwitch(switch)

#define sp_observeSwitchOnce(switch) \
		"should be called with @" @"".createSPStream(@"path", 1).addSwitch(switch)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeControl(control, event)
//	will create a SomePromiseDataStream observing UIControl gt event.
//	will be updated control ref. on each event.
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeControl(control, event) \
		"should be called with @" @"".createSPStream(@"path", 0).addControl(control, event)

#define sp_observeControlOnce(control, event) \
		"should be called with @" @"".createSPStream(@"path", 1).addControl(control, event)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeNSNotification(center, object, notification)
//	will create a SomePromiseDataStream observing notification for object from NSNotificationCenter
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeNSNotification(center, object, notification) \
		"should be called with @" @"".createSPStream(@"path", 0).addNSNotificationFromObjectAndCenter(notification, object, center)

#define sp_observeNSNotificationOnce(center, object, notification) \
		"should be called with @" @"".createSPStream(@"path", 1).addNSNotificationFromObjectAndCenter(notification, object, center)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeEvent(target, event)
//	will create a SomePromiseDataStream observing event from target.
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeEvent(target, event) \
		"should be called with @" @"".createSPStream(@"path", 0).addEvent(event, target)

#define sp_observeEventOnce(target, event) \
		"should be called with @" @"".createSPStream(@"path", 1).addEvent(event, target)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_observeExtend(target, extendName)
//	will create a SomePromiseDataStream observing target's extend with name.
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_observeExtend(target, extendName) \
		"should be called with @" @"".createSPStream(@"path", 0).addExtend(extendName, target)

#define sp_observeExtendOnce(target, extendName) \
		"should be called with @" @"".createSPStream(@"path", 1).addExtend(extendName, target)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//@sp_bind(object, key) bind value of property key in oject with SomePromiseDataStream.
// ex: @sp_bind(self, propertyName) = @sp_observe(object, objectProperty).map(^(NSString* value){
//									return [NSString stringWithFormat:@"%lu", (unsigned long)value.length];
//								});
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_bind(object, key) try{} @finally{} [[SPDataBinder alloc] initWith:object keyPath:[NSString stringWithUTF8String:#key]].stream

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//@sp_uibind(object, key) bind value of property key in oject with SomePromiseDataStream. And makes in on
// main thread always
// ex:@sp_uibind(_label, text) = @sp_observeTextField(_textField).map(^(NSString* value){
//									return [NSString stringWithFormat:@"text:%@, length:%lu", value, (unsigned long)value.length];
//								});
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_uibind(object, key) try{} @finally{} [[SPDataBinder alloc] initWith:object keyPath:[NSString stringWithUTF8String:#key] queue:dispatch_get_main_queue()].stream

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_start(action) will start the action.
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_start(action) try{} @finally{} action.stream

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_startUI(action) will start the action on main queue.
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_startUI(action) try{} @finally{} action.queue = dispatch_get_main_queue(); action.stream

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_startQueue(action, queue) will start the action on queue
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_startQueue(action, queue) try{} @finally{} action.queue = queue; action.stream

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//	@sp_startThread(action, thread) will start the action on thread
///////////////////////////////////////////////////////////////////////////////////////////////////////////
#define sp_startThread(action, thread) try{} @finally{}  action.thread = thread; action.stream

@class SPDataStream;
@class SPArray;

//block representing an action. value is the observed result to be used in action.
typedef void (^SPActionBlock)(id _Nullable value);

//block to get enabling/disabling the command.
typedef BOOL (^SPCommandEnableBlock)(void);

//block to return stream for the command.
typedef SPDataStream* (^SPCommandDataStreamBlock)(id input);

//block for command on stream got result
typedef void (^SPCommandDoNextBlock)(id data);

//block for command on stream got result
typedef void (^SPCommandDoErrorBlock)(NSError *error);

//block for command on stream completed
typedef void (^SPCommandDoCompleteBlock)(void);

//block to merge streams in one.
typedef id (^SPMergeRule)(SPArray*);

@class UITextField;
@class UITextView;
@class UISwitch;
@class UIControl;
@class SPAction;
typedef NS_OPTIONS(NSUInteger, UIControlEvents);

//function to create an action.
SPAction* sp_action(id object, SPActionBlock action);

////////////////////////////////////////////////////////////////
// SPDataStreamDelegate protocol
//
//	Delegate to datastream. Delegate is only one.
///////////////////////////////////////////////////////////////
@protocol SPDataStreamDelegate <NSObject>
@optional

/////////////////////////////////////////////////////////////////////
//- (void) stream:(SPDataStream*)stream hasIncomingData:(id)value
//	stream got the result.
//	It does not have this data as a result yet
//	This data could be rejected by filter or changed by map
// 	Use this method to check the original incomming data
/////////////////////////////////////////////////////////////////////
- (void) stream:(SPDataStream*)stream hasIncomingData:(id)value;

/////////////////////////////////////////////////////////////////////
// - (void) stream:(SPDataStream*)stream willUpdatedWith:(id)value
//	value is the original value before maps.
//	This means filters passed by the value.
////////////////////////////////////////////////////////////////////
- (void) stream:(SPDataStream*)stream willUpdatedWith:(id)value;

////////////////////////////////////////////////////////////////////
//- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value;
//	value is the value of stream. Aftre all maps.
//	Means the stream has been updated with this new value.
////////////////////////////////////////////////////////////////////
- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value;

/////////////////////////////////////////////////////////////////////
//- (void) stream:(SPDataStream*)stream gotError:(NSError*)error;
//	Stream has been provided with error
////////////////////////////////////////////////////////////////////
- (void) stream:(SPDataStream*)stream gotError:(NSError*)error;

/////////////////////////////////////////////////////////////////////
//- (void) streamCompleted:(SPDataStream*)stream
//	stream is now in comlete state, no more data could be accepted.
////////////////////////////////////////////////////////////////////
- (void) streamCompleted:(SPDataStream*)stream;

@end

//////////////////////////////////////////////////////////////////////////////////
// SPDataStreamObserver protocol
//	Observer protocol is just the same as delegate protocol
//	Observer to datastream. There could be many observers per one DataStream.
//////////////////////////////////////////////////////////////////////////////////
@protocol SPDataStreamObserver <SPDataStreamDelegate>
@end


@class SomePromiseThread;
//block to provide filtering of stream data.
typedef BOOL(^FilterBlock)(id);

//block to provide mapping for DataStream
typedef id(^MapBlock)(id);

//DataStream error listener
typedef void(^OnSPStreamErrorHandler)(SPDataStream*, NSError *);

//on complete listener
typedef void(^OnSPStreamCompletedHandler)(SPDataStream*);

///////////////////////////////////////////////////////////////////////////////////
// SPDataStream class.
//	Represets a simple stream wich has a value.
//	This value could be changed and could be read.
//	Also stream could has error and could be completed (no more data (or error)
//	could be provided.
//
//	Stream could filter data and change it using map rules
//
//	Streams could be combined in some ways (see below).
//
//	Also stream could observe objects using KVO or events.
//
///////////////////////////////////////////////////////////////////////////////////
@interface SPDataStream : NSObject

//delegate to the stream
@property (nonatomic, weak) id<SPDataStreamDelegate> delegate;

//last data
@property (nonatomic, readonly) id lastResult;
//last error.
@property (nonatomic, readonly) NSError *error;

//is completed
@property (nonatomic, readonly) BOOL completed;

//create new stream. Unlimited times.
+ (instancetype) new;

//create new stream wich will work on thread. (will call observers and delegate on thread).
//times - how many times stream could change value before been colesed.
// 0 - means unlimited time.
+ (instancetype) newOnThread:(SomePromiseThread*)thread times:(NSInteger) times;

//create new stream wich will work on queue. (will call observers and delegate on queue).
+ (instancetype) newOnQueue:(dispatch_queue_t) queue  times:(NSInteger) times;

//create new datastream to observe source's keypath using KVO.
//closeOnDestroy for this source is YES. (See below for closeOnDestroy)
+ (instancetype) newWithSource:(id)source keyPath:(NSString*)keyPath times:(NSInteger) times;

//create new datastream to observe source's keypath using KVO on queue. (will call observers and delegate on queue).
//closeOnDestroy for this source is YES. (See below for closeOnDestroy)
+ (instancetype) newWithSource:(id)source keyPath:(NSString*)keyPath queue:(dispatch_queue_t _Nonnull)queue  times:(NSInteger) times;

//create new datastream to observe source's keypath using KVO on thread. (will call observers and delegate on thread).
//closeOnDestroy for this source is YES. (See below for closeOnDestroy)
+ (instancetype) newWithSource:(id)source keyPath:(NSString*)keyPath thread:(SomePromiseThread *_Nonnull)thread  times:(NSInteger) times;

//init methods.
- (instancetype)initWithTimes:(NSInteger) times NS_DESIGNATED_INITIALIZER;

//will call observers and delegate on queue
-(instancetype)initWithQueue:(dispatch_queue_t _Nonnull)queue times:(NSInteger) times;

//will call observers and delegate on thread
- (instancetype)initWithThread:(SomePromiseThread *_Nonnull)thread  times:(NSInteger) times;

//init with observing source's keypath via KVO
//closeOnDestroy for this source is YES. (See below for closeOnDestroy)
- (instancetype)initWithSource:(id)source keyPath:(NSString*)keyPath  times:(NSInteger) times;

//init with observing source's keypath via KVO. Will call observers and delegate on queue
//closeOnDestroy for this source is YES. (See below for closeOnDestroy)
- (instancetype)initWithSource:(id)source keyPath:(NSString*)keyPath queue:(dispatch_queue_t _Nonnull)queue  times:(NSInteger) times;

//init with observing source's keypath via KVO. Will call observers and delegate on thread.
//closeOnDestroy for this source is YES. (See below for closeOnDestroy)
- (instancetype)initWithSource:(id)source keyPath:(NSString*)keyPath thread:(SomePromiseThread *_Nonnull)thread times:(NSInteger) times;

//Variants of combinig:

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// - (void) then:(SPDataStream*)stream;
//	Adds stream input to current output.
//	It means after the stream will be updated it will provide value to the next stream added by then method.
//	Stream could have several then streams. All of them will be provided with value.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) then:(SPDataStream*)stream;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void) follow:(SPDataStream*)stream;
//	Currrent stream(self) will follow the strem.
//	THe same as stream.then(self)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) follow:(SPDataStream*)stream;

//returns block to make then (tha same as in parameters). Block returns
//provided stream. So it is possible to do stream.then(stream1).then(stream2).thean(stream3)....then(streamN);
// stream -> stream1 -> stream2 -> stream3 ..... -> streamN
- (SPDataStream *_Nonnull(^ __nonnull)(SPDataStream *_Nonnull))then;

//returns block to make then (tha same as in parameters). Block returns self.
- (SPDataStream *_Nonnull(^ __nonnull)(SPDataStream *_Nonnull))follow;

//concat creates new stream with maps and filters from all of concatanated
//sources will not be added.
//So this is just a method to create new stream with ready maps and filters.
+ (instancetype)concat:(NSArray<SPDataStream*>*)streams;

// glue creates new stream wich will get all values from streams in method's parameters.
// All streams from array will do then(self)
+ (instancetype)glue:(NSArray<SPDataStream*>*)streams;

//////////////////////////////////////////////////////////////////////////////////////////////
//+ (instancetype)merge:(NSArray<SPDataStream*>*)streams withMergeRule:(SPMergeRule)mergeRule times:(NSInteger)times;
//	creates new stream from many streams from streams array using mergeRule.
//	Merge rule is a block wich takes all values from all merged streams and returns some merged result.
//	This result will be the result of the created stream.
//	Will be called on any each update of any stream from array.
//	If some stream does not have a value yet it will provide nil as a pramater to mergeRule.
//	If stream will have incomingNilIgnorring to YES mergedRule will be called only when all parameters will
//	have not nil values.
//	it means if you have several streams merged and one stream has been updated twice but second only once
//	The first update of the first stream will be just ignored.
//////////////////////////////////////////////////////////////////////////////////////////////
+ (instancetype)merge:(NSArray<SPDataStream*>*)streams withMergeRule:(SPMergeRule)mergeRule;

//returns stream queue or nil.
- (dispatch_queue_t _Nullable) queue;

//returns stream thread or nil.
- (SomePromiseThread *_Nullable) thread;

//stream could have a lot of sources and observe many keys in each.
//	closeOnDestroy - should stream be closed if this source destroyed.
//	When you create a stream with source (or initWithSource) closeOnDestroy
//	fr this source will be true.
- (void) addSource:(id)source keyPath:(NSString*)keyPath closeOnDestroy:(BOOL)yesNo;

//If source has been added with closeOnDestroy - YES
//stream will be closed on it's destoing despite the source has been removed.
- (void) removeSource:(id)source;
- (void) removeAllSources;

#if (TARGET_OS_IOS)
//start observing textField.text property.
//User change in UI and programmatically made changes.
//closeOnDestroy is always NO
- (void) addTextField:(UITextField*)textField API_AVAILABLE(ios(11));
- (void) removeTextField:(UITextField*)textField API_AVAILABLE(ios(11));
- (void) removeAllTextFields API_AVAILABLE(ios(11));;

//returns block to add textField
- (SPDataStream *_Nonnull(^ __nonnull)(UITextField *_Nonnull))addTextField API_AVAILABLE(ios(11));

//The same as for textField but for textView.
- (void) addTextView:(UITextView*)textView API_AVAILABLE(ios(11));
- (void) removeTextView:(UITextView*)textView API_AVAILABLE(ios(11));
- (void) removeAllTextViews API_AVAILABLE(ios(11));

//returns block to add textField
- (SPDataStream *_Nonnull(^ __nonnull)(UITextView *_Nonnull))addTextView API_AVAILABLE(ios(11));

//UISwitch will be observed for it's value (ON/OFF)
//by user change in UI and by programmatically made changes.
//closeOnDestroy is always NO
- (void) addSwitch:(UISwitch*)switchView API_AVAILABLE(ios(11));
- (void) removeSwitch:(UISwitch*)switchView API_AVAILABLE(ios(11));
- (void) removeAllSwitches API_AVAILABLE(ios(11));

//returns block to add switch.
- (SPDataStream *_Nonnull(^ __nonnull)(UISwitch *_Nonnull))addSwitch API_AVAILABLE(ios(11));

//start observing for UIControl on it's event.
//The result will be the control itself.
- (void) addControl:(UIControl*)control forEvent:(UIControlEvents)event API_AVAILABLE(ios(11)) API_AVAILABLE(ios(11));

//Note!: does not return any source. Only control.
- (void) removeControl:(UIControl*)control forEvent:(UIControlEvents)event API_AVAILABLE(ios(11)) API_AVAILABLE(ios(11));
//Note:!, this method could works odd on the first sight.
//Just if you have added UISwitch
//Than call this method.
//Your switch will be binded by KVO but not by UIControll target.
//This is right beheviour.
- (void) removeAllControlsForEvent:(UIControlEvents)event API_AVAILABLE(ios(11));

//retuens block to add UIControl.
- (SPDataStream *_Nonnull(^ __nonnull)(UIControl *_Nonnull, UIControlEvents))addControl API_AVAILABLE(ios(11));
#endif

//Start observing NSNotification with name.
- (void) addNSNotification:(NSString*_Nonnull)notificationName;

//Start observing NSNotification with name. from notification Center
- (void) addNSNotification:(NSString*_Nonnull)notificationName
	fromNotificationCenter:(NSNotificationCenter*_Nullable)center;

//Start observing NSNotification with name from object.
- (void) addNSNotification:(NSString*_Nonnull)notificationName
				fromObject:(id _Nullable)object;

//Start observing NSNotification with name from object. from notification Center
- (void) addNSNotification:(NSString*_Nonnull)notificationName
				fromObject:(id _Nullable)object
	fromNotificationCenter:(NSNotificationCenter*_Nullable)center;

//removing obserfing for NSNotifications
- (void) removeAllNSNotificationsForNotificationCenter:(NSNotificationCenter*_Nullable)center;
- (void) removeAllNSNotificationsForObject:(id _Nullable)object
					fromNotificationCenter:(NSNotificationCenter*_Nullable)center;
- (void) removeNSNotification:(NSString*_Nonnull)notificationName
	   fromNotificationCenter:(NSNotificationCenter*_Nullable)center;
- (void) removeNSNotification:(NSString *)notificationName
					forObject:(id _Nullable)object
	   fromNotificationCenter:(NSNotificationCenter*_Nullable)center;

//return blocks to start NSNotification observing
- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull))addNSNotification;
- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, NSNotificationCenter*_Nullable))addNSNotificationFromCenter;
- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nullable))addNSNotificationFromObject;
- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nullable, NSNotificationCenter *_Nullable))addNSNotificationFromObjectAndCenter;

//Observing for SomePromiseEvents
- (void) addEvent:(NSString*_Nonnull)event fromObject:(id _Nonnull)object;
- (void) removeEvent:(NSString*_Nonnull)event fromObject:(id _Nonnull)object;

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nonnull))addEvent;

//Observing for SomePromiseExtend
- (void) addExtend:(NSString*_Nonnull)extendName ofObject:(id _Nonnull)object;
- (void) removeExtend:(NSString*_Nonnull)extendName ofObject:(id _Nonnull)object;

- (SPDataStream *_Nonnull(^ __nonnull)(NSString*_Nonnull, id _Nonnull))addExtend;

//Ignore incoming nil.
//Not add nil as a last result and don't call observers and delegate with nil.
// setter and getter.
- (BOOL) incomingNilIgnorring;
- (void) ignoreIncomingNil:(BOOL)yesNo;

//returns block to set incomingNilIgnorring
- (SPDataStream *_Nonnull(^ __nonnull)(BOOL))ignoreIncomingNil;

//settters for queue/thread
- (void) setThread:(SomePromiseThread *_Nonnull)thread;
- (void) setQueue:(dispatch_queue_t _Nullable)queue;
- (SPDataStream *_Nonnull(^ __nonnull)(SomePromiseThread *_Nonnull))onThread;
- (SPDataStream *_Nonnull(^ __nonnull)(dispatch_queue_t _Nonnull))onQueue;

//adding/removing observers.
- (void) addObserver:(id<SPDataStreamObserver>)observer;
- (void) removeObserver:(id<SPDataStreamObserver>)observer;
- (void) removeObservers;
- (SPDataStream *_Nonnull(^ __nonnull)(id<SPDataStreamObserver>))addObserver;
- (SPDataStream *_Nonnull(^ __nonnull)(id<SPDataStreamObserver>))removeObserver;
- (SPDataStream *_Nonnull(^ __nonnull)(void))skipObservers;

///////////////////////////////////////////////////////////////////////////////////
//	- (void) skip;
//	set last result to nil with no observers calling.
//
///////////////////////////////////////////////////////////////////////////////////
- (void) skip;

//remove all filters
- (void) skipFilter;

//remove all maps
- (void) skipMap;

//	binding to result.
//	target is a listener owner.
//	listener will neve be called if the owner is destroyed.
//	listener is a block to be called on result update.
- (void) bind:(id)target listener:(SPListener)listener;
- (void) bindNext:(id)target listener:(SPListener)listener;
- (void) bindOnce:(id)target listener:(SPListener)listener;
- (void) unbind:(id)target;
- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull, SPListener _Nullable))bind;
- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull, SPListener _Nullable))bindNext;
- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull, SPListener _Nullable))bindOnce;
- (SPDataStream *_Nonnull(^ __nonnull)(id _Nonnull))unbind;

//adding filters and maps
- (void) addFilter:(FilterBlock)filter;
- (void) addMap:(MapBlock)map;
- (SPDataStream *_Nonnull(^ __nonnull)(FilterBlock))filter;
- (SPDataStream *_Nonnull(^ __nonnull)(MapBlock))map;

//Take returns nil if stream is closed(completed), even if it has not nil lastResult.
- (id) take;

//add listeners for error and closing
- (void) addOnErrorHandler:(OnSPStreamErrorHandler)handler;
- (void) addOnCompleteHandler:(OnSPStreamCompletedHandler)handler;
- (SPDataStream *_Nonnull(^ __nonnull)(OnSPStreamErrorHandler))onError;
- (SPDataStream *_Nonnull(^ __nonnull)(OnSPStreamCompletedHandler))onComplete;

//removing listeners
- (void) skipCompleteHandlers;
- (void) skipErrorHandlers;
- (void) skipHandlers;
- (void) unbindAll;

//provide a lastResult value.
- (void) doNext:(id)value;

//provide error
- (void) doError:(NSError*)error;

//complete the stream.
- (void) doComplete;

//take array values one by one and call doNext with each of them
- (void) fromArray:(NSArray*)array;

//The same as from array but sparray could contain nils
- (void) fromSPArray:(SPArray*)array;

//save not nil values in array.
//By default off.
//if on than off, all collected data will be omitted
// ! collectToArray does not collect nils.
- (void) collectToArray:(BOOL)onOff;

//The same as - (void) collectToArray:(BOOL)onOff;
//but collects to SPArray.
//SPArray could have nils.
- (void) collectToSPArray:(BOOL)onOff;

//get collected array.
- (NSArray *_Nullable) collectedArray;

//get collected SPArray.
- (SPArray *_Nullable) collectedSPArray;

@end

//SPDataBinder is used for BINDINGS.
//Bind object.keyPaht to DataStream.
//object key path property will take the same value as binded stream has.
//It will keep strong ref to self while you don't call
//discard.
//discard will be automatically called on object been removed
@interface SPDataBinder : NSObject

//will take ref on self after setting the stream.
@property (nonatomic, strong) SPDataStream *stream;

- (instancetype) initWith:(id) object keyPath:(NSString*)keyPath NS_DESIGNATED_INITIALIZER;
- (instancetype) initWith:(id) object keyPath:(NSString*)keyPath queue:(dispatch_queue_t)queue;
- (instancetype) initWith:(id) object keyPath:(NSString*)keyPath thread:(SomePromiseThread*)thread;

- (void) discard;

@end

//SPAction provides action on doNext of data stream
//action will be called on stream update.
//SPAction keeps strong ref to itself.
//Will set it to nil on discard.
//discard will be called automatically on objecct destroy.
@interface SPAction : NSObject

@property (nonatomic, strong) SPDataStream *stream;

@property (nonatomic) SomePromiseThread *thread;
@property (nonatomic) dispatch_queue_t queue;

//associated object is used for action life time.
- (instancetype) initWithAssociatedObject:(id _Nonnull)object action:(SPActionBlock _Nonnull)action NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithAssociatedObject:(id _Nonnull)object action:(SPActionBlock _Nonnull)action queue:(dispatch_queue_t _Nullable)queue;
- (instancetype) initWithAssociatedObject:(id _Nonnull)object action:(SPActionBlock _Nonnull)action thread:(SomePromiseThread *_Nullable)thread;
- (void) discard;

@end

//SPCommand
//has enableBLock to check if the command could be executed.
//streamBlock to provide the stream.
//doNextBlock - what to do on stream updating
//doErrorBlock - what to do on stream error
//doComplete - what to do on stream completd.
//execute:input - start the command with initial value for stream block.
//It means you can start the command with valuable input.
//! Note:
//  If command deleted, all it's block can not be executed.
// 	Despite this Stream can be created inside SPCommandDataStreamBlock wiht some asynchronious operation
//  running in separate NSThread or dispatch_queue or other way.
//	To avoid operations running for not existing stream check inside operatons
//	that stream is alive (not nil) and is not closed.
//!! Don't forget to provide weak pointer to stream inside operations.
//
@interface SPCommand : NSObject

- (instancetype)initWithEnableBlock:(SPCommandEnableBlock _Nullable)enableBlock
						streamBlock:(SPCommandDataStreamBlock _Nonnull)streamBlock
							 doNext:(SPCommandDoNextBlock _Nonnull)doNextBlock
							doError:(SPCommandDoErrorBlock _Nullable)doErrorBlock
						 doComplete:(SPCommandDoCompleteBlock _Nullable)doCompleteBlock;

- (BOOL) execute:(id) input;

@end

//There are some addition methods for NSObject
//To support streaming for object keyPath.
@interface NSObject (SPDataStream)

- (SPDataStream*) createSPStream:(NSString*)keyPath times:(NSInteger) times;
- (SPDataStream*) createSPStream:(NSString*)keyPath onQueue:(dispatch_queue_t)queue times:(NSInteger) times;
- (SPDataStream*) createSPStream:(NSString *)keyPath onThread:(SomePromiseThread*)thread times:(NSInteger) times;
//add self as source additionally, but not close on self destroy
- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath times:(NSInteger) times;
- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onQueue:(dispatch_queue_t)queue times:(NSInteger) times;
- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onThread:(SomePromiseThread*)thread times:(NSInteger) times;

- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, NSInteger times))createSPStream;
- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, id _Nonnull, NSInteger times))createSPStreamForObject;

@end

@interface NSProxy (SPDataStream)

- (SPDataStream*) createSPStream:(NSString*)keyPath  times:(NSInteger) times;
- (SPDataStream*) createSPStream:(NSString*)keyPath onQueue:(dispatch_queue_t)queue  times:(NSInteger) times;
- (SPDataStream*) createSPStream:(NSString *)keyPath onThread:(SomePromiseThread*)thread  times:(NSInteger) times;

//add self as source additionally, but not close on self destroy
- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath  times:(NSInteger) times;
- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onQueue:(dispatch_queue_t)queue  times:(NSInteger) times;
- (SPDataStream*) createSPStream:(id) object keyPath:(NSString*) keyPath onThread:(SomePromiseThread*)thread  times:(NSInteger) times;

- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, NSInteger times))createSPStream;
- (SPDataStream *_Nonnull(^ __nonnull)(NSString *_Nonnull, id _Nonnull, NSInteger times))createSPStreamForObject;

@end
