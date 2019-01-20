//
//  ChainOnThreadTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 20/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ChainOnThreadTestViewController.h"
#import "SomePromise.h"
#import "SomePromiseThread.h"

@interface NSNumberForFutureTest : NSObject
- (void) testMethod;
- (instancetype) initWithInt:(NSInteger)intValue;
@property (nonatomic, readwrite) NSInteger value;
@end

@implementation NSNumberForFutureTest
- (void) testMethod
{
    NSLog(@"!!!!!! <Future method called> %ld", self.value);
}

- (instancetype) initWithInt:(NSInteger)intValue
{
	self = [super init];
	
	if(self)
	{
	   self.value = intValue;
	}
	return self;
}

@end

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

@interface ChainOnThreadTestViewControllerObserver : NSObject <SomePromiseObserver>
@property (nonatomic, weak) UILabel *observerNameLabel;
@property (nonatomic, weak) UILabel *observerStatusLabel;
@property (nonatomic, weak) UILabel *observerResultLabel;
@property (nonatomic, weak) UILabel *observerErrorLabel;
@property (nonatomic, weak) UILabel *observerProgressLabel;
@end

@implementation ChainOnThreadTestViewControllerObserver
- (void) promise:(SomePromise*_Nonnull) promise gotResult:(id _Nonnull ) result
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
	    self.observerResultLabel.text = [NSString stringWithFormat:@"Result: %@", result];
	    self.observerErrorLabel.text = @"Error";
    });
}

- (void) promise:(SomePromise*_Nonnull) promise rejectedWithError:(NSError*_Nullable) error
{
    dispatch_async(dispatch_get_main_queue(), ^{
       self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
	   self.observerResultLabel.text = @"Result";
	   self.observerErrorLabel.text = [NSString stringWithFormat:@"Error: %@", error];
	});
}

- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
     dispatch_async(dispatch_get_main_queue(), ^{
        self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
        self.observerStatusLabel.text = [NSString stringWithFormat:@"Status old: %@, new: %@", statusAsString(oldStatus), statusAsString(newStatus)];
	});
}

- (void) promise:(SomePromise*_Nonnull) promise progress:(float) progress
{
   dispatch_async(dispatch_get_main_queue(), ^{
      self.observerNameLabel.text = [NSString stringWithFormat:@"Name: %@", promise.name];
      self.observerProgressLabel.text = [NSString stringWithFormat:@"Progress: %f", progress];
	});
}
@end

@interface ChainOnThreadTestViewController ()
{
   SomePromise *_promise;
   ChainOnThreadTestViewControllerObserver *_observer;
	__weak IBOutlet UIButton *startBtn;
	SomePromiseThread *thread;
}

@property (nonatomic, weak) IBOutlet UILabel *observerNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerStatusLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerResultLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerErrorLabel;
@property (nonatomic, weak) IBOutlet UILabel *observerProgressLabel;

@property (nonatomic, readonly)UIButton *startButton;
@end

@implementation ChainOnThreadTestViewController
@synthesize startButton = startBtn;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    thread = [SomePromiseThread threadWithName:@"test thread"];
    _observer = [[ChainOnThreadTestViewControllerObserver alloc] init];
    
}

- (void)viewDidAppear:(BOOL)animated
{
	_observer.observerNameLabel = self.observerNameLabel;
	_observer.observerStatusLabel = self.observerStatusLabel;
	_observer.observerResultLabel = self.observerResultLabel;
	_observer.observerErrorLabel = self.observerErrorLabel;
	_observer.observerProgressLabel = self.observerProgressLabel;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
													  onThread:thread
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   FulfillBlock([[NSNumberForFutureTest alloc] initWithInt:1000]);
								   } class: [NSNumberForFutureTest class]];

        SomePromiseFuture *future = [onePromise getFuture];
        NSNumberForFutureTest *number = [future getFuture];
        [number testMethod];

		SomePromise *promise1 = //[SomePromise promiseWithName:@"promise1 for after promiseS test" value:@(1000)];
		[SomePromise postpondedPromiseWithName:@"promise1 for after promiseS test"
													  onThread:thread
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
													  onThread:thread
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
													  onThread:thread
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


	__weak ChainOnThreadTestViewController *weakSelf = self;
	_promise = [SomePromise promiseWithName:@"Chain Test FirstPromise"
	                     onThread:thread
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
					 }class: nil ].thenOnThreadWithName(@"First then", nil, thread, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(2);
							 rejectBlock(nil);
					 }).thenElseOnThreadWithName(@"Second Then (else)", nil, thread, ^(ThenParams){}, ^(ElseParams){
					         progressBlock(3);
						     //here we demonstrate an else as a way to avoid errors in chain.
						     //Just provide previous result as previous (rejected) block does not exist
						     fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).onSuccess(^(NSNumber *result){
					    NSLog(@"Result after first reject (after else recovering) : %@", result);
					 }).thenOnThreadWithName(@"Third then", nil, thread, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(4);
							 fulfillBlock(@(20));
					  }).thenOnThreadWithName(@"Fourth then", nil, thread, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(5);
							 rejectBlock(nil);
					  }).thenOnThreadWithName(@"Fivth then", nil, thread, ^(ThenParams){
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 progressBlock(6);
							 fulfillBlock(@(30));
					 }).onReject(^(NSError* error){
						     NSLog(@"Fivth then rejected dueto fourth was rejected - right");
					 }).ifRejectedThenOnThread(nil, thread, ^(ThenParams){
					     NSLog(@"Result after second reject (should be 20) : %@", lastValuesInChain.lastResultInChain);
					     progressBlock(7);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).thenOnThreadWithName(@"6th then", nil, thread, ^(ThenParams){
					     progressBlock(8);
						 fulfillBlock(result);
					 }).ifRejectedThenOnThreadWithName(@"7th ifRejected", nil, thread, ^(ThenParams){
					     progressBlock(9);
					     NSLog(@"Error: this should not be called due yo last promise was not rejected");
						 fulfillBlock(@(100));
	                 }).onSuccess(^(NSNumber *result){
					    NSLog(@"Result should be 20 : %@", result);
					 }).afterOnThreadWithName(@"8th after 2.0", nil, thread,  2.0, ^(ThenParams){
					    progressBlock(10);
					    fulfillBlock(@(200));
					 }).afterOnThreadWithName(@"9th after 2.0", nil, thread, 2.0, ^(ThenParams){
					    progressBlock(11);
					    rejectBlock(nil);
					 }).ifRejectedThenOnThreadWithName(@"10th ifRejectedThen", nil, thread, ^(ThenParams){
					     progressBlock(12);
					     NSLog(@"Result after 9th reject (should be 200) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).afterPromiseOnThreadWithName(@"11th after promise", nil, thread, onePromise, ^(ThenParams){
					     progressBlock(13);
						 fulfillBlock(onePromise.result);
					 }).afterPromiseOnThreadWithName(@"12th after promise", nil, thread, onePromise, ^(ThenParams){
					     progressBlock(14);
						 rejectBlock(nil);
					 }).ifRejectedThenOnThreadWithName(@"13th ifRejectedThen", nil, thread, ^(ThenParams){
					     progressBlock(15);
					     NSLog(@"Result after 13th reject (should be 1000) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).onSuccess(^(NSNumber *result){
						 [promise1 start];
						 [promise2 start];
						 [promise3 start];
					 }).afterPromisesOnThreadWithName(@"14th after promiseS", nil, thread, @[promise1, promise2, promise3], ^(ThenParams){
					     progressBlock(16);
						 fulfillBlock(@([promise1.result integerValue] + [promise2.result integerValue] + [promise3.result integerValue]));
					 }).afterPromisesOnThreadWithName(@"15th after promiseS", nil, thread, @[promise1, promise2, promise3], ^(ThenParams){
					     progressBlock(17);
						 rejectBlock(nil);
				     }).ifRejectedThenOnThreadWithName(@"16th ifRejectedThen", nil, thread, ^(ThenParams){
				         progressBlock(18);
					     NSLog(@"Result after 15th reject (should be 3000) : %@", lastValuesInChain.lastResultInChain);
						 fulfillBlock(lastValuesInChain.lastResultInChain);
					 }).whenOnThreadWithName(@"17th when promise", nil, thread, ^(StdBlocks){
					        progressBlock(19);
						    fulfillBlock(@"100");
					    }, ^(ResultParams){
					         progressBlock(20);
					         NSLog(@"17th when result, last result in chain: %@, must be 3000", lastValuesInChain.lastResultInChain);
							 fulfillBlock(result);
					 }).whenOnThreadWithName(@"18th when promise", nil, thread, ^(StdBlocks){
					         progressBlock(21);
					         rejectBlock(nil);
					   }, ^(ResultParams){
					         progressBlock(22);
					         NSLog(@"18th when result, last result in chain: %@, must be 100", lastValuesInChain.lastResultInChain);
							 rejectBlock(nil);
                     }).ifRejectedThenOnThreadWithName(@"19th ifRejectedThen", nil, thread, ^(ThenParams){
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
					 }).addChainObserverOnThread(thread, _observer);
		[_promise setChainThread:thread];
}

- (IBAction)rejectPressed:(id)sender
{
   [_promise rejectAllInChain];
}

@end
