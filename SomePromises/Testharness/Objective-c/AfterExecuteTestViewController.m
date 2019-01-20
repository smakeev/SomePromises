//
//  AfterExecuteTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 21/02/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "AfterExecuteTestViewController.h"
#import "SomePromise.h"

@interface AfterExecuteTestViewController ()
@property (weak, nonatomic) IBOutlet UIButton *afterTimeButton;
@property (weak, nonatomic) IBOutlet UILabel *afterTimeResult;
@property (weak, nonatomic) IBOutlet UILabel *afterPromisePromiseStatus;
@property (weak, nonatomic) IBOutlet UILabel *afterPromiseResult;
@property (weak, nonatomic) IBOutlet UIButton *afterPromiseButton;
@property (weak, nonatomic) IBOutlet UIButton *afterPromisesButton;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *finalResult;


@end

@implementation AfterExecuteTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)afterTimeTest:(id)sender
{
   __weak AfterExecuteTestViewController *weakSelf = self;
   self.afterTimeButton.enabled = NO;
   self.afterTimeResult.text = @"Label";
   [[SomePromise promiseWithName:@"Test Promise" value:Void class: nil] after:10.0 execute:^(ThenParams)
    {
         dispatch_async(dispatch_get_main_queue(), ^{
                             if(weakSelf)
                             {
							     weakSelf.afterTimeResult.text = @"Finished";
							     weakSelf.afterTimeButton.enabled = YES;
							 }
		  });
		  fulfillBlock(Void);
    } class: nil];
}

- (IBAction)afterPromise:(id)sender
{
   __weak AfterExecuteTestViewController *weakSelf = self;
   self.afterPromiseButton.enabled = NO;
   self.afterPromiseResult.text = @"Label";
   self.afterPromisePromiseStatus.text = @"After promise status.";
	
   SomePromise *promise = [SomePromise promiseWithName: @"Promise to wait for"
					 resolvers: ^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 0; i < 2; ++i)
						     {
						         sleep(1);
								 result += i;
							 }
							 fulfillBlock(@(result));
					 } class: nil].onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
							 if(weakSelf)
                             {
		                        weakSelf.afterPromisePromiseStatus.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
							 }
		                 });
	                 });

	[[SomePromise promiseWithName: @"Test Promise" value:Void class: nil]
	                afterPromise: promise
	                     execute: ^(ThenParams)
	                     {
							 NSInteger newValue = 100 + [promise.result integerValue];
							 fulfillBlock(@(newValue));
                         } class: nil].onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
								 if(weakSelf)
                                 {
								     weakSelf.afterPromiseResult.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
								     weakSelf.afterPromiseButton.enabled = YES;
								 }
		                 });
	                 });

}

- (IBAction)afterPromisesPressed:(id)sender
{
   __weak AfterExecuteTestViewController *weakSelf = self;
   self.afterPromisesButton.enabled = NO;
   self.label1.text = @"label1";
   self.label2.text = @"label2";
   self.label3.text = @"label3";
   self.finalResult.text = @"Label_Result";
	
   SomePromise *promise1 = [SomePromise promiseWithName: @"Promise1 to wait for"
					 resolvers: ^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 0; i < 2; ++i)
						     {
						         sleep(1);
								 result += i;
							 }
							 fulfillBlock(@(result));
					 } class: nil].onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
						  if(weakSelf)
						  {
		                      weakSelf.label1.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
						  }
		                 });
	                 });
	
   SomePromise *promise2 = [SomePromise promiseWithName: @"Promise2 to wait for"
					 resolvers: ^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 2; i < 4; ++i)
						     {
						         sleep(1);
								 result += i;
							 }
							 fulfillBlock(@(result));
					 } class: nil].onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
						  if(weakSelf)
						  {
		                     weakSelf.label2.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
						  }
		                 });
	                 });
	
   SomePromise *promise3 = [SomePromise promiseWithName: @"Promise3 to wait for"
					 resolvers: ^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 4; i < 6; ++i)
						     {
						         sleep(1);
								 result += i;
							 }
							 fulfillBlock(@(result));
					 } class: nil].onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
						  if(weakSelf)
						  {
		                      weakSelf.label3.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
						  }
		                 });
	                 });
	
	[[SomePromise promiseWithName: @"Test Promise" value:Void class: nil]
	                afterPromises: @[promise1, promise2, promise3]
	                     execute: ^(ThenParams)
	                     {
							 NSInteger newValue = [promise1.result integerValue] + [promise2.result integerValue] + [promise3.result integerValue];
							 fulfillBlock(@(newValue));
                         } class: nil].onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
							if(weakSelf)
						    {
							   weakSelf.finalResult.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
							   weakSelf.afterPromisesButton.enabled = YES;
							}
		                 });
	                 });
}

@end
