//
//  ChainTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 23/03/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ChainTestViewController.h"
#import "SomePromise.h"

static NSString* statusAsString(PromiseStatus status)
{
   switch (status)
   {
	  case ESomePromiseUnknown:
		   return @"Unknown";
      case ESomePromiseNonActive:
		   return @"NonActive";
      case ESomePromisePending:
		   return @"Pending";
      case ESomePromiseSuccess:
		   return @"Success";
      case ESomePromiseRejected:
           return @"Rejected";
   }
	
   return nil;
}

@interface ChainTestObserver: NSObject <SomePromiseObserver>
@property (nonatomic, weak) UILabel *observerNameLabel;
@property (nonatomic, weak) UILabel *observerStatusLabel;
@property (nonatomic, weak) UILabel *observerResultLabel;
@property (nonatomic, weak) UILabel *observerErrorLabel;
@property (nonatomic, weak) UILabel *observerProgressLabel;

@end

@implementation ChainTestObserver

- (void) promise:(SomePromise*_Nonnull) promise gotResult:(id _Nonnull ) result
{
    self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
	self.observerResultLabel.text = [NSString stringWithFormat:@"Result: %@", result];
	self.observerErrorLabel.text = @"Error";
	
}

- (void) promise:(SomePromise*_Nonnull) promise rejectedWithError:(NSError*_Nullable) error
{
self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
	self.observerResultLabel.text = @"Result";
	self.observerErrorLabel.text = [NSString stringWithFormat:@"Error: %@", error];
}

- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
     self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
     self.observerStatusLabel.text = [NSString stringWithFormat:@"Status old: %@, new: %@", statusAsString(oldStatus), statusAsString(newStatus)];
}

- (void) promise:(SomePromise*_Nonnull) promise progress:(float) progress
{
   self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
   self.observerProgressLabel.text = [NSString stringWithFormat:@"Progress: %f", progress];
}
@end

@interface ChainTestViewController ()
{
   SomePromise *_promise;
   ChainTestObserver *_observer;
	__weak IBOutlet UIButton *startBtn;
}

@property (nonatomic, weak) IBOutlet UILabel *observerNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerStatusLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerResultLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerErrorLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerProgressLabel;

@property (nonatomic, readonly)UIButton *startButton;

@end

@implementation ChainTestViewController
@synthesize startButton = startBtn;
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _observer = [[ChainTestObserver alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
	_observer.observerNameLabel = self.observerNameLabel;
	_observer.observerStatusLabel = self.observerStatusLabel;
	_observer.observerResultLabel = self.observerResultLabel;
	_observer.observerErrorLabel = self.observerErrorLabel;
	_observer.observerProgressLabel = self.observerProgressLabel;
}

-(IBAction)startTest:(id)sender
{
    self.observerNameLabel.text = @"Name";
	self.observerResultLabel.text = @"Result";
	self.observerErrorLabel.text = @"Error";
	self.observerStatusLabel.text = @"Status";
	self.observerProgressLabel.text = @"Progress";
	
    startBtn.enabled = NO;
	
	SomePromise *onePromise = [SomePromise promiseWithName:@"promise for after promise test"
													   onQueue:nil//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 100; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock(@(1000));
								   } class: nil];

		SomePromise *promise1 = //[SomePromise promiseWithName:@"promise1 for after promiseS test" value:@(1000)];
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
								   } class: nil];

		SomePromise *promise2 = //[SomePromise promiseWithName:@"promise2 for after promiseS test" value:@(1000)];
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
								   } class: nil];

		SomePromise *promise3 = //[SomePromise promiseWithName:@"promise3 for after promiseS test" value:@(1000)];
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
								   } class: nil];


	__weak ChainTestViewController *weakSelf = self;
	_promise = [SomePromise promiseWithName:@"Chain Test FirstPromise"
	                     onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	                     delegate:nil
	                     delegateQueue:nil
					 resolvers:^(BaseBlocks(fulfillBlock, rejectBlock))
					 {
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(1);
							 fulfillBlock(@(10));
					 } class: nil].thenWithName(@"First then", nil, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(2);
							 rejectBlock(nil);
					 }).thenElseWithName(@"Second Then (else)", nil, ^(ThenParams){}, ^(ElseParams){
					         progressBlock(3);
						     //here we demonstrate an else as a way to avoid errors in chain.
						     //Just provide previous result as previous (rejected) block does not exist
						     fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).onSuccess(^(NSNumber *result){
					    NSLog(@"Result after first reject (after else recovering) : %@", result);
					 }).thenWithName(@"Third then", nil, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(4);
							 fulfillBlock(@(20));
					  }).thenWithName(@"Fourth then", nil, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(5);
							 rejectBlock(nil);
					  }).thenWithName(@"Fivth then", nil, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(6);
							 fulfillBlock(@(30));
					 }).onReject(^(NSError* error){
						     NSLog(@"Fivth then rejected dueto fourth was rejected - right");
					 }).ifRejectedThen(nil, ^(ThenParams){
					     NSLog(@"Result after second reject (should be 20) : %@", lastValuesInChain.lastResultInChain);
					     progressBlock(7);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).thenWithName(@"6th then", nil, ^(ThenParams){
					     progressBlock(8);
						 fulfillBlock(result);
					 }).ifRejectedThenWithName(@"7th ifRejected", nil, ^(ThenParams){
					     progressBlock(9);
					     NSLog(@"Error: this should not be called due yo last promise was not rejected");
						 fulfillBlock(@(100));
	                 }).onSuccess(^(NSNumber *result){
					    NSLog(@"Result should be 20 : %@", result);
					 }).afterWithName(@"8th after 2.0", nil, 2.0, ^(ThenParams){
					    progressBlock(10);
					    fulfillBlock(@(200));
					 }).afterWithName(@"9th after 2.0", nil, 2.0, ^(ThenParams){
					    progressBlock(11);
					    rejectBlock(nil);
					 }).ifRejectedThenWithName(@"10th ifRejectedThen", nil, ^(ThenParams){
					     progressBlock(12);
					     NSLog(@"Result after 9th reject (should be 200) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).afterPromiseWithName(@"11th after promise", nil, onePromise, ^(ThenParams){
					     progressBlock(13);
						 fulfillBlock(onePromise.result);
					 }).afterPromiseWithName(@"12th after promise", nil, onePromise, ^(ThenParams){
					     progressBlock(14);
						 rejectBlock(nil);
					 }).ifRejectedThenWithName(@"13th ifRejectedThen", nil, ^(ThenParams){
					     progressBlock(15);
					     NSLog(@"Result after 13th reject (should be 1000) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).onSuccess(^(NSNumber *result){
						 [promise1 start];
						 [promise2 start];
						 [promise3 start];
					 }).afterPromisesWithName(@"14th after promiseS", nil, @[promise1, promise2, promise3], ^(ThenParams){
					     progressBlock(16);
						 fulfillBlock(@([promise1.result integerValue] + [promise2.result integerValue] + [promise3.result integerValue]));
					 }).afterPromisesWithName(@"15th after promiseS", nil, @[promise1, promise2, promise3], ^(ThenParams){
					     progressBlock(17);
						 rejectBlock(nil);
				     }).ifRejectedThenWithName(@"16th ifRejectedThen", nil, ^(ThenParams){
				         progressBlock(18);
					     NSLog(@"Result after 15th reject (should be 3000) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).whenWithName(@"17th when promise", nil, ^(StdBlocks){
					        progressBlock(19);
						    fulfillBlock(@"100");
					    }, ^(ResultParams){
					         progressBlock(20);
					         NSLog(@"17th when result, last result in chain: %@, must be 3000", lastValuesInChain.lastResultInChain);
							 fulfillBlock(result);
					 }).whenWithName(@"18th when promise", nil, ^(StdBlocks){
					         progressBlock(21);
					         rejectBlock(nil);
					   }, ^(ResultParams){
					         progressBlock(22);
					         NSLog(@"18th when result, last result in chain: %@, must be 100", lastValuesInChain.lastResultInChain);
							 rejectBlock(nil);
                     }).ifRejectedThenWithName(@"19th ifRejectedThen", nil, ^(ThenParams){
						 progressBlock(23);
					     NSLog(@"Result after 18th reject (should be 100) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).alwaysOnMain(^(Always(result, error)){
						    if(weakSelf)
						    {
						       weakSelf.startButton.enabled = YES;
						    }
					 }).onEachSuccess(^(NSString *promiseName, id result){
					     NSLog(@"%@ Complete with result: %@",promiseName, result);
					 }).onEachReject(^(NSString *promiseName,NSError *error){
						 NSLog(@"%@ REjected with error: %@",promiseName, error);
					 }).onEachProgress(^(NSString *promiseName,float progress){
					     NSLog(@"%@ Progress: %f", promiseName, progress);
					 }).addChainObserver(dispatch_get_main_queue(), _observer);
}

- (IBAction)rejectPressed:(id)sender
{
   [_promise rejectAllInChain];
}


@end
