//
//  FifthViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 07/02/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "FifthViewController.h"
#import "SomePromise.h"

@interface FifthViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation FifthViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)start:(id)sender
{

   __weak FifthViewController *weakSelf = self;
   self.startButton.enabled = NO;
	ProgressBlock progressBlock = ^(float progress)
	{
	    dispatch_async(dispatch_get_main_queue(), ^
	    {
	       weakSelf.progressLabel.text = [NSString stringWithFormat:@"%f%%", progress];
		});
	};
	
   [[[[[[[[[SomePromise promiseWithName:@"5th test promise"
					 resolvers:^(AllBlocksWithNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock))
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
					 } class: nil] onProgress:progressBlock]
					 thenExecute:^(ThenParams)
					 {
							 int nextResult = 0;
						     for(int i = 20; i < 40; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 nextResult += i;
							 }
							 int finalResult = (int)[result integerValue] + nextResult;
							 fulfillBlock(@(finalResult));
					 } class: nil] onProgress:progressBlock]
					 thenExecute:^(ThenParams)
					 {
							 int nextResult = 0;
						     for(int i = 40; i < 60; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 nextResult += i;
							 }
							 int finalResult = (int)[result integerValue] + nextResult;
							 fulfillBlock(@(finalResult));
					 } class: nil] onProgress:progressBlock]
					 thenExecute:^(ThenParams)
					 {
							 int nextResult = 0;
						     for(int i = 60; i <= 100; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
								 nextResult += i;
							 }
							 int finalResult = (int)[result integerValue] + nextResult;
							 fulfillBlock(@(finalResult));
					  } class : nil] onProgress:progressBlock]
					     onSuccess:^(NSNumber *result)
					     {
					       dispatch_async(dispatch_get_main_queue(), ^
					       {
							  weakSelf.resultLabel.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
							  weakSelf.startButton.enabled = YES;
					       });
					  }];
}


@end
