//
//  SomePromiseThread.h
//  SomePromises
//
//  Created by Sergey Makeev on 31/03/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

//=======================================================================================================================
//*	class SomePromiseThread represents a thread.
//
//	works similar to serial queue.
//	Added tasks will be started one after another.
//	But it is guranteed to be launched in the same thread.
//	You can add blocks and invocations.
//	When thread does not have active tasks it sleeps.
//	Also it is possible to run timers on thread.
// 	In case of active timer thread is active even if no other tasks.
//	After all timers invalidates and no more active tasks thread will sleep again.
//
//	Is not a subclass of NSThread, does not provide any start method.
//  But you can easily subclass and add start method providing some block as a start point.
//	Just call stop after the end of the block execution.
//=======================================================================================================================


#import <Foundation/Foundation.h>

@interface SomePromiseThread : NSObject

/************************************************************************************************************************
*
*	property name.
*
*	Name of the thread. Using for debug. Two or more threads can have the same name.
*	There is no way to get ref. to the thread by it's name.
*
*************************************************************************************************************************/
@property (nonatomic, readonly) NSString *name;

/************************************************************************************************************************
*
*	+ (instancetype) threadWithName:(NSString *_Nonnull) name
*
*	Create new thread with name and default quality of service
*
*************************************************************************************************************************/
+ (instancetype) threadWithName:(NSString *_Nonnull) name;

/************************************************************************************************************************
*
*	+ (instancetype) threadWithName:(NSString *_Nonnull) name qualityOfService:(NSQualityOfService) qualityOfService
*
*	Create new thread with name and quality of service
*
*************************************************************************************************************************/
+ (instancetype) threadWithName:(NSString *_Nonnull) name qualityOfService:(NSQualityOfService) qualityOfService;

// return current thread quality of service
@property (readonly) NSQualityOfService qualityOfService;

// working means thread can handle incoming task.
// It does not mean that thread is active now (working on some task).
// Returns if it can perform selector or not. NO - Thread is stopped
- (BOOL) working;


// Is it now active or not.
//	Active - means currantly some action is in progress. NO - thread is sleeping
//	Action could be block, invocation or timer.
- (BOOL) active;

//Stop the thread.
//After stop thread will ignore tasks adding.
//Note:! Stop does not stop thread immidiatly. After finishing all active blocks it will be stopped.
//	So all tasks added before stop will be executed.
- (void) stop;

//recreate a thread. Old thread will be stopped
//Note it creates new thread inside and stops the old one.
- (void) restart;
- (void) restartWithQualityOfService:(NSQualityOfService) qualityOfService;

//Adding tasks:
/************************************************************************************************************************
*	- (void) performBlock:(void(^ _Nonnull)(void)) block;
*	Add block to tasks.
*************************************************************************************************************************/
- (void) performBlock:(void(^ _Nonnull)(void)) block;

/************************************************************************************************************************
*	- (void) performBlockOnMain:(dispatch_block_t)block
*	Add block to tasks. Block will be started on main thread insted of this thread, but thread will be waiting for it's ending.
*************************************************************************************************************************/
- (void) performBlockOnMain:(dispatch_block_t)block;

/************************************************************************************************************************
*	- (void) performBlock:( void(^ _Nonnull )(void)) block afterDelay:(NSTimeInterval) delay;
*	Add block to tasks. Task will be started after delay.
*	Delay will be started only when the task is active.
*	So if you have many tasks before, delay will be actually longer.
*************************************************************************************************************************/
- (void) performBlock:( void(^ _Nonnull )(void)) block afterDelay:(NSTimeInterval) delay;

/************************************************************************************************************************
*	- (void) performBlockSynchroniously:(void(^ _Nonnull)(void)) block;
*	Add block to tasks. Task will be started synchroniously.
*************************************************************************************************************************/
- (void) performBlockSynchroniously:(void(^ _Nonnull)(void)) block;

/************************************************************************************************************************
*	- (void) performInvocation:(NSInvocation*)invocation
*	Add invocation to tasks.
*************************************************************************************************************************/
- (void) performInvocation:(NSInvocation*)invocation;

/************************************************************************************************************************
*	- (void) performInvocation:(NSInvocation*)invocation afterDelay:(NSTimeInterval) delay;
*	Add invocation to tasks. Task will be started after delay.
*	Delay will be started only when the task is active.
*	So if you have many tasks before, delay will be actually longer.
*************************************************************************************************************************/
- (void) performInvocation:(NSInvocation*)invocation afterDelay:(NSTimeInterval) delay;

/************************************************************************************************************************
*	- (void) performInvocationSynchroniously:(NSInvocation*)invocation
*	Add invocation to tasks. Task will be started synchroniously.
*************************************************************************************************************************/
- (void) performInvocationSynchroniously:(NSInvocation*)invocation;

//timers
/************************************************************************************************************************
*	- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo
*	schedule timer for invocation.
*************************************************************************************************************************/
- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo;

/************************************************************************************************************************
*	- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;
*	schedule timer for target with selector.
*************************************************************************************************************************/
- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo;

/************************************************************************************************************************
*	- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block
*	schedule timer for block.
*************************************************************************************************************************/
- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block;

@end
