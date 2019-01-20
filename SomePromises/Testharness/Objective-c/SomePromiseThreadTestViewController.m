//
//  SomePromiseThreadTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 31/03/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseThreadTestViewController.h"
#import "SomePromiseThread.h"
#import "SomePromise.h"

static NSString* stringFromBool(BOOL var)
{
    if (var)
      return @"active";
    return @"waiting";
}


@interface SomePromiseThreadTestViewController ()
{
   SomePromiseThread *_thread;
   NSTimer *_repTimer;
   NSTimer *_noRepTimer;
}
@end

@implementation SomePromiseThreadTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	_thread = [SomePromiseThread threadWithName:@"Test thread"];
	
	//defer test
	
	
}

- (IBAction)isActivePressed:(id)sender {
    NSLog(@"Thread is %@", stringFromBool(_thread.active));
}

- (IBAction)addSimpleBlock:(id)sender {
	
    void(^simpleBlock)(void) = ^(void)
    {
       NSLog(@"Block start");
       sleep(12);
       NSLog(@"Block Executed");
    };

	[_thread performBlock:simpleBlock];
}

- (IBAction)addSimpleBlockAfterDelay:(id)sender{
    void(^simpleBlock)(void) = ^(void)
    {
       NSLog(@"Delayed Block executed");
       sleep(1);
    };
    
    [_thread performBlock:simpleBlock afterDelay:10.0];
}

//test method:
- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
    NSLog(@"Promise: %@ status was %lu current status is: %lu", promise.name, (unsigned long)oldStatus, (unsigned long)newStatus);
}

- (IBAction)addMethod:(id)sender
{
     SomePromise *promise = [SomePromise promiseWithName:@"Test"
									value:@"10" class: nil];

     SEL selector = @selector(promise:stateChangedFrom:to:);
	
	 PromiseStatus status1 = ESomePromisePending;
	 PromiseStatus status2 = ESomePromiseSuccess;
	
     NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
     [inv setTarget:self];
     [inv setSelector:selector];
	 [inv setArgument:&promise atIndex:2];
     [inv setArgument:&status1 atIndex:3];
     [inv setArgument:&status2 atIndex:4];
	
	 [_thread performInvocation:inv];
}

- (IBAction)blockWithParameters:(id)sender
{
	FutureBlock block = ^(FulfillBlock fl, RejectBlock rj, IsRejectedBlock iRj, ProgressBlock pr, id result, id<SomePromiseLastValuesProtocol> chain)
	{
		fl(@100);
	};
	
	FulfillBlock fl = ^(id result)
	{
	    NSLog(@"result block %@", result);
	};
	
	RejectBlock rj = ^(NSError *error)
	{
	   NSLog(@"rehect block %@", error);
	};
	
	IsRejectedBlock iRj = ^BOOL(void)
	{
	   return NO;
	};
	
	ProgressBlock pr = ^(float progress)
	{
	   NSLog(@"progress block");
	};
	
	NSInvocation *invocation = [NSInvocation invocationForBlock:block, [fl copy], [rj copy], [iRj copy], [pr copy], @(10), nil];
	[_thread performInvocation:invocation];
}

- (IBAction)stopPressed:(id)sender {
   [_thread stop];
}

- (IBAction)restartPressed:(id)sender {
   [_thread restart];
}

- (IBAction)isWorkingPressed:(id)sender {
   NSLog(@"Thread working: %d", _thread.working);
}

- (void) timerTestFunc:(NSNumber*)number
{
	NSLog(@"!!!Timer :%ld", [number integerValue]);
}

- (IBAction)addTimer:(id)sender
{
	_repTimer = [_thread scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(timerTestFunc:) userInfo:@(97) repeats:YES];
	[_repTimer fire];
}

- (IBAction)invalidate:(id)sender
{
   [_repTimer invalidate];
}

- (IBAction)addTimerNoRepeat:(id)sender
{
	_noRepTimer = [_thread scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(timerTestFunc:) userInfo:@(97) repeats:NO];
	//[_noRepTimer fire];
}

- (IBAction)noRepeatInvalidate:(id)sender
{
   [_noRepTimer invalidate];
}


@end
