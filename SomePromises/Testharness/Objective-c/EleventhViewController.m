//
//  EleventhViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 20/02/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "EleventhViewController.h"

#import "SomePromise.h"

@interface EleventhViewController ()
@property (weak, nonatomic) IBOutlet UILabel *firstTestLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondTestLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdTestLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthTestLabel;
@property (weak, nonatomic) IBOutlet UIButton *t1btn;
@property (weak, nonatomic) IBOutlet UIButton *t2btn;
@property (weak, nonatomic) IBOutlet UIButton *t3btn;
@property (weak, nonatomic) IBOutlet UIButton *t4btn;

@end

@implementation EleventhViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)pressFirst:(id)sender
{
  __weak EleventhViewController *weakSelf = self;
  self.t1btn.enabled = NO;
  self.firstTestLabel.text = @"Label";
  [[SomePromise promiseWithName:@"11th test promise"
					 resolvers:^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 0; i < 20; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 result += i;
							 }
							 fulfillBlock(@(result));
					 } class: nil].ifRejectedThen(nil, ^(ElseParams)
					 {
						 dispatch_async(dispatch_get_main_queue(), ^{
							if (weakSelf)
							{
							   weakSelf.firstTestLabel.text = @"Finished";
							}
							fulfillBlock(Void);
						 });
					 }) onSuccess:^(id result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
						   if (weakSelf)
                           {
							  weakSelf.t1btn.enabled = YES;
						   }
                        });
                     }];

}

- (IBAction)pressSecond:(id)sender
{
  __weak EleventhViewController *weakSelf = self;
  self.t2btn.enabled = NO;
  self.secondTestLabel.text = @"Label";
  [[SomePromise promiseWithName:@"11th test promise"
					 resolvers:^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 0; i < 20; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 result += i;
							 }
							 NSDictionary *userInfo = @{
                                  NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
							       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                             };
                             NSError *error = [NSError errorWithDomain:@"test.domain"
                                     code:-57
                                 userInfo:userInfo];
							 rejectBlock(error);
					 } class: nil].ifRejectedThen(nil, ^(ElseParams)
					 {
						dispatch_async(dispatch_get_main_queue(), ^{
						     if (weakSelf)
                             {
							    weakSelf.secondTestLabel.text = @"Finished";
							 }
						 });
						 fulfillBlock(Void);
					 }) onSuccess:^(id result)
					 {
                        dispatch_async(dispatch_get_main_queue(), ^{
                           if (weakSelf)
                           {
							   weakSelf.t2btn.enabled = YES;
						   }
                        });
                     }];
}


- (IBAction)pressThird:(id)sender
{
  __weak EleventhViewController *weakSelf = self;
  self.t3btn.enabled = NO;
  self.thirdTestLabel.text = @"Label";
  [[SomePromise promiseWithName:@"11th test promise"
					 resolvers:^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 0; i < 20; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 result += i;
							 }
							 fulfillBlock(@(result));
					 } class: nil].ifRejectedThen(nil, ^(ElseParams)
					 {
						 dispatch_async(dispatch_get_main_queue(), ^{
							if (weakSelf)
                            {
							    weakSelf.thirdTestLabel.text = @"Finished";
							}
							 fulfillBlock(Void);
						 });
					 }) onSuccess:^(id result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
							if (weakSelf)
                            {
							   weakSelf.t3btn.enabled = YES;
							}
                        });
                     }];
}


- (IBAction)pressFourth:(id)sender
{
  __weak EleventhViewController *weakSelf = self;
  self.t4btn.enabled = NO;
  self.fourthTestLabel.text = @"Label";
  [[SomePromise promiseWithName:@"11th test promise"
					 resolvers:^(StdBlocks)
					 {
					         int result = 0;
						     for(int i = 0; i < 20; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 result += i;
							 }
							 NSDictionary *userInfo = @{
                                  NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
							       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                             };
                             NSError *error = [NSError errorWithDomain:@"test.domain"
                                     code:-57
                                 userInfo:userInfo];
							 rejectBlock(error);
					 } class: nil].ifRejectedThen(nil, ^(ElseParams)
					 {
						 dispatch_async(dispatch_get_main_queue(), ^{
						   if (weakSelf)
                           {
							 weakSelf.fourthTestLabel.text = @"Finished";
							}
							fulfillBlock(Void);
						 });
					 }) onSuccess:^(id result)
					 {
                        dispatch_async(dispatch_get_main_queue(), ^{
						   if (weakSelf)
                           {
							   weakSelf.t4btn.enabled = YES;
						   }
                        });
                     }];
}

@end

