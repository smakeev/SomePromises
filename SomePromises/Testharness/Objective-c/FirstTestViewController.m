//
//  FirstTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 12/01/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "FirstTestViewController.h"

#import "SomePromise.h"

@interface FirstTestViewController () <SomePromiseDelegate>
{
   NSInteger promises;
}

@end

@implementation FirstTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    promises = 0;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPromise:(id)sender
{
	[SomePromise promiseWithName:[NSString stringWithFormat:@"Success_Promise: %ld", (long)++promises]
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 FulfillBlock(@(1000));
					 } class: nil];
}

- (IBAction)startRejectedPromise:(id)sender
{
	[SomePromise promiseWithName:[NSString stringWithFormat:@"Rejected_Promise: %ld", (long)++promises]
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 rejectBlock(rejectionErrorWithText(@"test error", 200));
					 } class: nil];
}


- (IBAction)startPromiseWithDelegate:(id)sender
{
    [SomePromise promiseWithName:[NSString stringWithFormat:@"Success_Promise: %ld", (long)++promises]
					   onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
					  delegate:self
				 delegateQueue:dispatch_get_main_queue()
				    resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 FulfillBlock(@(1000));
					 } class: nil];
}

- (IBAction)startRejectedPromiseWithDelegate:(id)sender
{
	[SomePromise promiseWithName:[NSString stringWithFormat:@"Rejected_Promise: %ld", (long)++promises]
	                     onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	                     delegate:self
	                     delegateQueue:dispatch_get_main_queue()
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 rejectBlock(nil);
					 } class: nil];
}

- (IBAction)startPospondedPromise:(id)sender
{
		[[SomePromise postpondedPromiseWithName:[NSString stringWithFormat:@"Success_Promise: %ld", (long)++promises]
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 FulfillBlock(@(1000));
					 } class: nil] start];
}

- (IBAction)startPostpondedRejectedPromise:(id)sender
{
	[[SomePromise postpondedPromiseWithName:[NSString stringWithFormat:@"Rejected_Promise: %ld", (long)++promises]
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 rejectBlock(nil);
					 } class: nil] start];
}

- (IBAction)startPostpondedPromiseWithDelegate:(id)sender
{
    [[SomePromise postpondedPromiseWithName:[NSString stringWithFormat:@"Success_Promise: %ld", (long)++promises]
					   onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
					  delegate:self
				 delegateQueue:dispatch_get_main_queue()
				    resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 FulfillBlock(@(1000));
					 } class: nil] start];
}

- (IBAction)startPostpondedRejectedPromiseWithDelegate:(id)sender
{
	[[SomePromise postpondedPromiseWithName:[NSString stringWithFormat:@"Rejected_Promise: %ld", (long)++promises]
	                     onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	                     delegate:self
	                     delegateQueue:dispatch_get_main_queue()
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 rejectBlock(nil);
					 } class: nil] start];
}

- (IBAction)startMethodTest:(id)sender
{
     NSLog(@"Start testing of start method has no effect on already started promises");
	
     NSLog(@"Predefined success");
     SomePromise *success = [SomePromise promiseWithName:@"SUCCESS_PREDEFINED_PROMISE" value:@"Some Value For Test" class: nil];
	 [success start];
	 NSLog(@"Predefined Rejected");
	 SomePromise *reject = [SomePromise promiseWithName:@"REJECT_PREDEFINED_PROMISE" error:nil class: nil];
	 [reject start];
	 NSLog(@"Promise SUCCESS");
	 SomePromise *success2 = [SomePromise promiseWithName:@"SUCCESS_LAUNCHING"
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
							 FulfillBlock(@(1000));
					 } class: nil];
	 [success2 start];
	 SomePromise *reject2 = [SomePromise promiseWithName:@"REJECT_LAUNCHING"
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
							 rejectBlock(nil);
					 } class: nil];
	 [reject2 start];
	SomePromise *postponded = [SomePromise postpondedPromiseWithName:[NSString stringWithFormat:@"START_POSTPONDED_Promise: %ld", (long)++promises]
	                     onQueue:dispatch_get_main_queue()
	                     delegate:self
	                     delegateQueue:dispatch_get_main_queue()
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
							 rejectBlock(nil);
					 } class: nil];
     [postponded start]; //should pass
	 [postponded start];
	 [postponded start]; //two messages Can't start.
	
}

- (void) promise:(SomePromise*_Nonnull) promise gotResult:(id _Nonnull ) result
{
     NSLog(@"Promise: %@ finished with result: %@", promise.name, result);
}

- (void) promise:(SomePromise*_Nonnull) promise rejectedWithError:(NSError*_Nullable) error
{
      NSLog(@"Promise: %@ rejected with error", promise.name);
}

- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
	NSLog(@"Promise: %@ status was %lu current status is: %lu", promise.name, (unsigned long)oldStatus, (unsigned long)newStatus);
}

@end
