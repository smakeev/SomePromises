//
//  EighthViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 13/02/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "EighthViewController.h"
#import "SomePromise.h"

@interface EighthViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation EighthViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)start:(id)sender
{

   __weak EighthViewController *weakSelf = self;
   self.startButton.enabled = NO;
	ProgressBlock progressBlock = ^(float progress)
	{
	    dispatch_async(dispatch_get_main_queue(), ^
	    {
	       weakSelf.progressLabel.text = [NSString stringWithFormat:@"%f%%", progress];
		});
	};
	
   [SomePromise promiseWithName:@"8th test promise"
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
					 } class: nil].onProgress(^(float progress)
                       {
                          progressBlock(progress);
                       })
					 .when(nil, ^(StdBlocks)
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
							 fulfillBlock(@(nextResult));
					 },^(ResultParams)
					 {
						 NSInteger finalResult = (int)[ownerResult integerValue]  + (int)[result integerValue];
						 fulfillBlock(@(finalResult));
					 }).onProgress(^(float progress)
					   {
					      progressBlock(progress);
					   })
					 .when(nil, ^(StdBlocks)
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
							 fulfillBlock(@(nextResult));
					 },
					 ^(ResultParams)
					 {
						 NSInteger finalResult = (int)[ownerResult integerValue]  + (int)[result integerValue];
						 fulfillBlock(@(finalResult));
					 }).onProgress(^(float progress)
					 {
						 progressBlock(progress);
					 })
					 .when(nil, ^(StdBlocks)
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
							 fulfillBlock(@(nextResult));
					  },
					  ^(ResultParams)
					  {
						 NSInteger finalResult = (int)[ownerResult integerValue]  + (int)[result integerValue];
						 fulfillBlock(@(finalResult));
					  }).onProgress(^(float progress)
					 {
						 progressBlock(progress);
					 }).onSuccess(^(NSNumber *result)
					     {
					       dispatch_async(dispatch_get_main_queue(), ^
					       {
							  weakSelf.resultLabel.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
							  weakSelf.startButton.enabled = YES;
					       });
					  });
}

@end

