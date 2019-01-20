//
//  SomePromiseSignal.h
//  SomePromises
//
//  Created by Sergey Makeev on 15/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SomePromiseThread;

/*
    SomePromiseSignal
    Is just a sort of Data wich could be sent to any object by another object.
 
    You may owerride this class to have your own signal.
    But it provides a lot of varians in default.
*/

@interface SomePromiseSignal : NSObject

// Name of the signal. Can be used as NSString id for a Signal type
@property(nonatomic, copy, readonly) NSString *name;
// Tag is a number id of the signal, or just any number if you want.
@property(nonatomic, readonly)NSInteger tag;
// Message is a dictionary wich could be provided to the object.
@property(nonatomic, readonly)NSDictionary *message;
// If message dictionary is not what you want, just send anything else
@property(nonatomic, readonly)id anythingElse;
// handled is a flag if send the signal to the next target or not.
@property(nonatomic, readonly)BOOL handled;
// This is writable field for any target. Using this field targets in one chain are able
// to share info to each other.
@property(nonatomic)id additionalinfo; //can be managed by any target.

- (instancetype) initWithName:(NSString*)name tag:(NSInteger)tag message:(NSDictionary*)message anythingElse:(id)anythingElse;

@end

//Each instance can send signal to another instance and handle signals.

@interface NSProxy (SomePromiseSignal)
/*=========================================================================================
- (void) sendSignal:(SomePromiseSignal*)signal toObject:(NSArray<id>*)targets;
Note!: Don't owerride this method.
Send signal to each target from targets array one by one.
wait for each target finish before send to the next.

Note!: If target marks signal as Handled (see below how to do this) signal will not be sent to the
next target.

==========================================================================================*/
- (void) sendSignal:(SomePromiseSignal*)signal toObject:(NSArray<id>*)targets;

/*=========================================================================================
- (SomePromiseThread*)threadForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;
Note!: Owerride this method to provide queue.
Return Thread for signal handling. By default is nil.

Note!: if both threadForHandlingSignal and queueForHandlingSignal return nil (or you did not owerride any
of them) signal will be handled in current context.

==========================================================================================*/
- (SomePromiseThread*)threadForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;

/*=========================================================================================
- (dispatch_queue_t)queueForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;
Note!: Owerride this method to provide thread.
Return queue for signal handling. By default is nil.

Note!: if both threadForHandlingSignal and queueForHandlingSignal return nil (or you did not owerride any
of them) signal will be handled in current context

==========================================================================================*/
- (dispatch_queue_t)queueForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;

/*=========================================================================================
- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal;
Note!: Owerride this method to be able to handle the signal.

To filter, if signal should be handled return YES.

Note!: By default is NO for all signals

==========================================================================================*/
- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal;

/*=========================================================================================
- (void)handleTheSignal:(SomePromiseSignal*)signal;

Note!: Owerride this method to handle the signal with your logic.

To handle the signal.
By default signal will be set as handled with no additional actions.
Call [super handleTheSignal:signal]; in any place of implementation to set signal handled to YES
If you don't call [super handleTheSignal:signal]; your action (signal handling) will be performed
but signal will be sent to the next object in the chain if there is one.

Note!: Next target will not be asked about the signal if it is handled.

Note!: If you want other target to see this event than don't call [super handleTheSignal:signal];

==========================================================================================*/
 - (void)handleTheSignal:(SomePromiseSignal*)signal;

@end

@interface NSObject (SomePromiseSignal)

/*=========================================================================================
- (void) sendSignal:(SomePromiseSignal*)signal toObject:(NSArray<id>*)targets;
Note!: Don't owerride this method.
Send signal to each target from targets array one by one.
wait for each target finish before send to the next.

Note!: If target marks signal as Handled (see below how to do this) signal will not be sent to the
next target.

==========================================================================================*/
- (void) sendSignal:(SomePromiseSignal*)signal toObject:(NSArray<id>*)targets;

/*=========================================================================================
- (SomePromiseThread*)threadForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;
Note!: Owerride this method to provide queue.
Return Thread for signal handling. By default is nil.

Note!: if both threadForHandlingSignal and queueForHandlingSignal return nil (or you did not owerride any
of them) signal will be handled in current context.

==========================================================================================*/
- (SomePromiseThread*)threadForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;

/*=========================================================================================
- (dispatch_queue_t)queueForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;
Note!: Owerride this method to provide thread.
Return queue for signal handling. By default is nil.

Note!: if both threadForHandlingSignal and queueForHandlingSignal return nil (or you did not owerride any
of them) signal will be handled in current context

==========================================================================================*/
- (dispatch_queue_t)queueForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender;

/*=========================================================================================
- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal;
Note!: Owerride this method to be able to handle the signal.

To filter, if signal should be handled return YES.

Note!: By default is NO for all signals

==========================================================================================*/
- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal;

/*=========================================================================================
- (void)handleTheSignal:(SomePromiseSignal*)signal;

Note!: Owerride this method to handle the signal with your logic.

To handle the signal.
By default signal will be set as handled with no additional actions.
Call [super handleTheSignal:signal]; in any place of implementation to set signal handled to YES
If you don't call [super handleTheSignal:signal]; your action (signal handling) will be performed
but signal will be sent to the next object in the chain if there is one.

Note!: Next target will not be asked about the signal if it is handled.

Note!: If you want other target to see this event than don't call [super handleTheSignal:signal];

==========================================================================================*/
- (void)handleTheSignal:(SomePromiseSignal*)signal;

@end
