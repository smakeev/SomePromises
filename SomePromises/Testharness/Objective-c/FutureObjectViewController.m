//
//  FutureObjectViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 23/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "FutureObjectViewController.h"
#import "SomePromise.h"


@interface TestClass : NSObject

@end

@implementation TestClass

- (BOOL) returnWithBool
{
   NSLog(@"returnWithBool");
   return YES;
}

- (TestClass*) returnClass
{
   NSLog(@"returnWithClass");
   return self;
}

- (NSNumber*) returnWithNumber
{
   NSLog(@"returnWithNumber");
   return @23;
}

- (void) voidReturn
{
   NSLog(@"Void return");
}

@end

@interface FutureObjectViewController ()
{
    SomePromiseFuture<TestClass*> *futureToTest;
	__weak IBOutlet UIButton *resolveButton;
	__weak IBOutlet UIButton *resolveWithErrorButton;
}


@end

@implementation FutureObjectViewController

- (void)viewDidLoad
 {
    [super viewDidLoad];
    SomePromiseThread *thread = [SomePromiseThread threadWithName:@"Future test thread"];
	futureToTest = [[SomePromiseFuture alloc] initWithThread:thread class:[TestClass class]];
	 
    SomePromiseFuture<TestClass*> *future = [[SomePromiseFuture alloc] initWithThread:thread class:[TestClass class]];
    TestClass *number = [future getFuture];
	 
    [number voidReturn];
    [number voidReturn];
    [number voidReturn];
	 
    [number returnWithNumber];
	[number returnClass];
	[number returnWithBool];
    [future resolveWithObject: [[TestClass alloc] init]];
    NSLog(@"______Test of asynch get _____");
	SomePromise *onePromise = [SomePromise promiseWithName:@"promise for get future test"
													   onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock(@(1000));
								   } class: NSNumber.class];
	NSLog(@" result: %@", [onePromise.getFuture get]);
}

- (IBAction)addChain:(id)sender {
    SomePromise *onePromise = [SomePromise promiseWithName:@"promise for after promise test"
													   onQueue:nil//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock(@(1000));
								   } class: nil];

		SomePromise *promise1 =
		[SomePromise postpondedPromiseWithName:@"promise1 for after promiseS test"
													   onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock(@(1000));
									   NSLog(@"Promise1 finished");
								   } class: nil];

		SomePromise *promise2 =
		 [SomePromise postpondedPromiseWithName:@"promise2 for after promiseS test"
													   onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock(@(1000));
									   NSLog(@"Promise2 finished");
								   } class: nil];

		SomePromise *promise3 =
		[SomePromise postpondedPromiseWithName:@"promise3 for after promiseS test"
													   onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock(@(1000));
									   NSLog(@"Promise3 finished");
								   } class: nil];
	
	   futureToTest.then(nil, ^(ThenParams){
                          NSLog(@"First then in chain");
						  rejectBlock(nil);
					 }).ifRejectedThen(nil, ^(ThenParams){
						 NSLog(@"Inside chain");
						 [promise1 start];
						 [promise2 start];
						 [promise3 start];
						 
						 fulfillBlock(Void);
					 }).afterPromise(nil, onePromise, ^(ThenParams){
						 NSLog(@"Inside chain after promise");
						 fulfillBlock(Void);
					 }).afterPromises(nil, @[promise1, promise2, promise3], ^(ThenParams){
					     NSLog(@"After promises");
					     fulfillBlock(Void);
					 }).onSuccess(^(NoResult){
					    NSLog(@"Chain completed");
					 });
}

- (IBAction)addWhenPromise:(id)sender {
   [futureToTest addWhenPromiseWithName:@"WhenPromise for Test" resolvers:^(ThenBlocks) {
   NSLog(@"Doing things when");
   fulfillBlock(Void);
} finalResult:^(ResultParams) {
	NSLog(@"Final of when");
	fulfillBlock(Void);
   } class: nil];
}

- (IBAction)addPromise:(id)sender {
	[futureToTest addPromiseWithName:@"Promise for Test" success:^(ThenParams) {
		NSLog(@"Future succeded with result %@", result);
		fulfillBlock(Void);
    } rejected:^(ElseParams) {
      NSLog(@"Future rejected with error %@", error);
      rejectBlock(error);
	} class: nil];

}

- (IBAction)resolveFuture:(id)sender {
   resolveButton.enabled = NO;
   resolveWithErrorButton.enabled = NO;
   [futureToTest resolveWithObject: [[TestClass alloc] init]];
}

- (IBAction)resolveFutureWithError:(id)sender {
   resolveButton.enabled = NO;
   resolveWithErrorButton.enabled = NO;
   [futureToTest resolveWithError:nil];
}

@end
