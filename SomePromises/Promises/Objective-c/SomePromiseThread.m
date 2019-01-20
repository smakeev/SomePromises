//
//  SomePromiseThread.m
//  SomePromises
//
//  Created by Sergey Makeev on 31/03/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseThread.h"
#import "SomePromiseUtils.h"
#import <objc/runtime.h>



@interface _SomePromiseThread : NSThread
{
    NSTimer *_internalTimer;
    NSCondition* _condition; //to notifay we have a block
    BOOL _isActive;
	
    NSInteger _timersCount;
}

@property (atomic) BOOL done;
@property (nonatomic) BOOL runningTask;
@property (nonatomic, readonly) NSCondition* condition;
@property (nonatomic, readonly) BOOL isActive;

- (void) timerDone;
- (void) runBlock:(void(^ _Nonnull)(void)) block;
- (void) runBlockOnMain:(void(^ _Nonnull)(void)) block;

@end

@interface _InternalNSTimerProxy : NSProxy
{
    @public
    NSTimer *_timer;
	__weak _SomePromiseThread *_thread;
}

- (instancetype)init;

+ (_InternalNSTimerProxy*)timerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo thread:(_SomePromiseThread*)thread;
+ (_InternalNSTimerProxy*)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo  thread:(_SomePromiseThread*)thread;
+ (_InternalNSTimerProxy *)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block  thread:(_SomePromiseThread*)thread;

@end

@implementation _InternalNSTimerProxy

- (instancetype)init
{
   self->_timer = nil;
   return self;
}

+ (_InternalNSTimerProxy*)timerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesNo thread:(_SomePromiseThread*)thread
{
     _InternalNSTimerProxy *proxy = [[_InternalNSTimerProxy alloc] init];
     proxy->_thread = thread;
     __weak _SomePromiseThread* _thread = thread;
     proxy->_timer =  [NSTimer timerWithTimeInterval:ti repeats:yesNo block:^(NSTimer* timer)
     {
		 BOOL repeats = yesNo;
	     [invocation invoke];
		 if(!repeats)
         {
			[_thread timerDone];
		 }
	 }];
	
     return proxy;
}

+ (_InternalNSTimerProxy*)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesNo thread:(_SomePromiseThread*)thread
{
     _InternalNSTimerProxy *proxy = [[_InternalNSTimerProxy alloc] init];
	 proxy->_thread = thread;
     __weak _SomePromiseThread* _thread = thread;
     proxy->_timer =  [NSTimer timerWithTimeInterval:ti repeats:yesNo block:^(NSTimer* timer)
     {
          BOOL repeats = yesNo;
          if([aTarget respondsToSelector:aSelector])
          {
			  if(userInfo == nil)
			  {
			      ((void (*)(id, SEL))[aTarget methodForSelector:aSelector])(aTarget, aSelector);
			  }
			  else
			  {
			     ((void (*)(id, SEL, id))[aTarget methodForSelector:aSelector])(aTarget, aSelector, userInfo);
			  }
		  }
		  else
		  {
		     [aTarget doesNotRecognizeSelector:aSelector];
		  }
		 
		if(!repeats)
        {
			[_thread timerDone];
		}
	 }];

     return proxy;
}

+ (_InternalNSTimerProxy *)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)yesNo block:(void (^)(NSTimer *timer))block thread:(_SomePromiseThread*)thread
{
     _InternalNSTimerProxy *proxy = [[_InternalNSTimerProxy alloc] init];
	 proxy->_thread = thread;
     __weak _SomePromiseThread* _thread = thread;
     proxy->_timer = [NSTimer timerWithTimeInterval:interval repeats:yesNo block:^(NSTimer *timer)
     {
	    BOOL repeats = yesNo;
        block(timer);
        if(!repeats)
        {
			[_thread timerDone];
		}
     }];
     return proxy;
}

- (void) invalidate
{
   [_timer invalidate];
   [_thread timerDone];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{
   	return [NSTimer instanceMethodSignatureForSelector:selector];
}

+ (BOOL)respondsToSelector:(SEL)aSelector
{
    return [NSTimer respondsToSelector:aSelector];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	
     void(^block)(void) = ^(){
          [invocation invokeWithTarget:self->_timer];
     };
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform block on stopped thread (working = NO)");
       return;
	}
	
	[_thread performSelector:@selector(runBlock:) onThread:_thread withObject:[block copy] waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];

}

@end

/// Thread

@interface _BlockDelayWrapper : NSObject

@property (nonatomic, copy, readwrite)void (^block)(void);
@property (nonatomic)NSInvocation *invocation;
@property (nonatomic)NSTimeInterval delay;

@end

@implementation _BlockDelayWrapper

- (instancetype) initWithBlock:(void(^ _Nonnull)(void)) block delay:(NSTimeInterval) interval
{
   self = [super init];
   if(self)
   {
	   self.block = block;
	   self.delay = interval;
   }
	
   return self;
}

- (instancetype) initWithInvocation:(NSInvocation*) invocation delay:(NSTimeInterval) interval
{
   self = [super init];
   if(self)
   {
      self.invocation = invocation;
      self.delay = interval;
   }
	
   return self;
}

@end

@implementation _SomePromiseThread

- (instancetype)init
{
   self = [super init];
   if (self)
   {
	  _condition = [[NSCondition alloc] init];
   }
	
   return self;
}

- (void)main
{
    NSRunLoop *rl = [NSRunLoop currentRunLoop];
    do
    {
		[_condition lock];
        while(!self.runningTask && _timersCount == 0)
        {
            _isActive = NO;
			[_condition wait];
		}
		self.runningTask = NO;
		_isActive = YES;
		[_condition unlock];
		[rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		#ifdef DEBUG
		NSLog(@"Thread %@ After run loop", self.name);
	    #endif
	} while(!self.done);
	[_condition lock];
	_isActive = NO;
	[_condition unlock];
}

#ifdef DEBUG
- (void) dealloc
{
	NSLog(@"Thread %@ dealloc", self.name);
}
#endif
- (void) runBlock:(void(^ _Nonnull)(void)) block
{
    block();
}

- (void) runBlockOnMain:(void(^ _Nonnull)(void)) block
{
	if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void) runTimerInvocation:(NSInvocation*) invocation
{
    [invocation performSelector:@selector(invoke) onThread:self withObject:nil waitUntilDone:NO];
	[self->_condition lock];
	if(self->_timersCount != 0)
	{
       self->_timersCount -= 1;
	}
	[self->_condition unlock];
}

- (void) runTimerBlock:(void(^ _Nonnull)(void)) block
{
    block();
	[self->_condition lock];
	if(self->_timersCount != 0)
	{
       self->_timersCount -= 1;
	}
	[self->_condition unlock];
}

- (void) runBlockWithWrapper:(_BlockDelayWrapper*)wrapper
{
	NSTimer *timer =[NSTimer timerWithTimeInterval:wrapper.delay repeats:NO block:^(NSTimer * _Nonnull timer) {
       [self performSelector:@selector(runTimerBlock:) onThread:self withObject:wrapper.block waitUntilDone:NO];
    }];
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	[rl addTimer:timer forMode:NSDefaultRunLoopMode];
	[_condition lock];
	self.runningTask = YES;
	_timersCount += 1;
	[_condition unlock];
}

- (void) runInvocationWithWrapper:(_BlockDelayWrapper*)wrapper
{
	NSTimer *timer =[NSTimer timerWithTimeInterval:wrapper.delay repeats:NO block:^(NSTimer * _Nonnull timer) {
       [self performSelector:@selector(runTimerInvocation:) onThread:self withObject:wrapper.invocation waitUntilDone:NO];
    }];
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	[rl addTimer:timer forMode:NSDefaultRunLoopMode];
	[_condition lock];
	self.runningTask = YES;
	_timersCount += 1;
	[_condition unlock];
}

- (void) scheduleTimer:(NSTimer*) timer
{
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	[rl addTimer:timer forMode:NSDefaultRunLoopMode];
	[_condition lock];
	self.runningTask = YES;
	_timersCount += 1;
	[_condition unlock];
}

- (void) timerDone
{
   	[self performSelector:@selector(runBlock:) onThread:self withObject:^(){} waitUntilDone:NO];
	[_condition lock];
	if(_timersCount != 0)
	{
	   _timersCount -= 1;
    }
	[_condition signal];
	[_condition unlock];
}

@end

@interface SomePromiseThread()
{
    _SomePromiseThread *_thread;
    NSQualityOfService _qualityOfService;
}
@property (nonatomic, copy) NSString *name;

@end

@implementation SomePromiseThread

+ (instancetype) threadWithName:(NSString *_Nonnull) name
{
    return [[SomePromiseThread alloc] initWithName: name qualityOfService:NSQualityOfServiceDefault];
}

+ (instancetype) threadWithName:(NSString *_Nonnull) name qualityOfService:(NSQualityOfService) qualityOfService
{
    return [[SomePromiseThread alloc] initWithName: name qualityOfService: qualityOfService];
}

- (instancetype) initWithName:(NSString * _Nonnull) name qualityOfService:(NSQualityOfService) qualityOfService
{
    self = [super init];
    if (self)
    {
		self.name = name;
		_thread = [[_SomePromiseThread alloc] init];
		_thread.name = self.name;
		_qualityOfService = qualityOfService;
		_thread.qualityOfService = _qualityOfService;
		[_thread start];
	}
	
	return self;
}

- (void) performStopBlock
{
	[_thread performSelector:@selector(runBlock:) onThread:_thread withObject:^(){} waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}

- (void) performBlock:( void(^ _Nonnull )(void)) block
{
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform block on stopped thread (working = NO)");
       return;
	}
	
	[_thread performSelector:@selector(runBlock:) onThread:_thread withObject:[block copy] waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}


- (void) performBlock:( void(^ _Nonnull )(void)) block afterDelay:(NSTimeInterval) delay
{
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform block on stopped thread (working = NO)");
       return;
	}
	
	_BlockDelayWrapper *wrapper = [[_BlockDelayWrapper alloc] initWithBlock:block delay:delay];
	[_thread performSelector:@selector(runBlockWithWrapper:) onThread:_thread withObject:wrapper waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}

- (void)performBlockOnMain:(dispatch_block_t)block
{
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform block on stopped thread (working = NO)");
       return;
	}
	
	[_thread performSelector:@selector(runBlockOnMain:) onThread:_thread withObject:[block copy] waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}


- (void) performBlockSynchroniously:(void(^ _Nonnull)(void)) block
{
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform block on stopped thread (working = NO)");
       return;
	}
	
	[_thread performSelector:@selector(runBlock:) onThread:_thread withObject:[block copy] waitUntilDone:YES];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}

- (void) performInvocation:(NSInvocation*)invocation
{
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform invocation on stopped thread (working = NO)");
       return;
	}
	
	[invocation performSelector:@selector(invoke) onThread:_thread withObject:nil waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}

- (void) performInvocation:(NSInvocation*)invocation afterDelay:(NSTimeInterval) delay
{
    if (_thread.done)
    {
       NSLog(@"SomePromises WARNING: attempt to perform invocation on stopped thread (working = NO)");
       return;
	}
	
	_BlockDelayWrapper *wrapper = [[_BlockDelayWrapper alloc] initWithInvocation:invocation delay:delay];
	[_thread performSelector:@selector(runInvocationWithWrapper:) onThread:_thread withObject:wrapper waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}

- (void) performInvocationSynchroniously:(NSInvocation*)invocation
{
    if (_thread.done)
    {
	   NSLog(@"SomePromises WARNING: attempt to perform invocation on stopped thread (working = NO)");
       return;
	}
	
	[invocation performSelector:@selector(invoke) onThread:_thread withObject:nil waitUntilDone:YES];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
}

- (NSQualityOfService) qualityOfService
{
   return _thread.qualityOfService;
}

- (BOOL) working
{
    return !_thread.done;
}

- (BOOL) active
{
   BOOL result;
   [_thread.condition lock];
   result = _thread.isActive;
   [_thread.condition unlock];
   return result;
}

- (void)stop
{
   if(_thread.done)
   {
      NSLog(@"SomePromises WARNING: attempt to stop stopped thread (working = NO)");
      return;
   }
	
   _thread.done = YES;
  [self performStopBlock];//empty block to go out of run loop
}

- (void) dealloc
{
  [self stop];
}

- (void) restart
{
   [self restartWithQualityOfService:_qualityOfService];
}

- (void) restartWithQualityOfService:(NSQualityOfService) qualityOfService
{
   if(!_thread.done)
   {
      [self stop];
   }
	  _qualityOfService = qualityOfService;
	  _thread = [[_SomePromiseThread alloc] init];
      _thread.name = self.name;
      _thread.qualityOfService = _qualityOfService;
      [_thread start];
	
}

//timers
- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo
{
	_InternalNSTimerProxy *timer = [_InternalNSTimerProxy timerWithTimeInterval:ti invocation:invocation repeats:yesOrNo thread: _thread];
	[_thread performSelector:@selector(scheduleTimer:) onThread:_thread withObject:timer->_timer waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
	return (NSTimer*)timer;
}

- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo
{
    _InternalNSTimerProxy *timer = [_InternalNSTimerProxy timerWithTimeInterval:ti target:aTarget selector:aSelector userInfo:userInfo repeats:yesOrNo thread: _thread];
    [_thread performSelector:@selector(scheduleTimer:) onThread:_thread withObject:timer->_timer waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
	return (NSTimer*)timer;
}

- (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block
{
    _InternalNSTimerProxy *timer = [_InternalNSTimerProxy timerWithTimeInterval:interval repeats:repeats block:block thread: _thread];
    [_thread performSelector:@selector(scheduleTimer:) onThread:_thread withObject:timer->_timer waitUntilDone:NO];
	[_thread.condition lock];
	_thread.runningTask = YES;
	[_thread.condition signal];
	[_thread.condition unlock];
    return (NSTimer*)timer;
}

@end
