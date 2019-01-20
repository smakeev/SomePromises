//
//  SixthViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 12/02/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SixthViewController.h"
#import "SomePromise.h"

@interface SixthViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startBTN;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation SixthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (ProgressBlock) progressBlock
{
	__weak SixthViewController *weakSelf = self;
	ProgressBlock progressBlock = ^(float progress)
	{
	    dispatch_async(dispatch_get_main_queue(), ^
	    {
	       weakSelf.progressLabel.text = [NSString stringWithFormat:@"%f%%", progress];
		});
	};
	
	return progressBlock;
}

- (SomePromise*) startingPromise
{
   __weak SixthViewController *weakSelf = self;
   return [[SomePromise promiseWithName:@"6th test promise"
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
					 } class: nil] onProgress: weakSelf ? weakSelf.progressBlock : nil]
					 .onSuccess(^(NSNumber *result)
					 {
		                dispatch_async(dispatch_get_main_queue(), ^
		                {
						  if(weakSelf)
                          {
		                      weakSelf.resultLabel.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
						   }
		                 });
	                 });
}

- (IBAction)start:(id)sender
{
   self.startBTN.enabled = NO;
   self.resultLabel.text = @"...";
   __weak SixthViewController *weakSelf = self;
   self.startingPromise
   .then(nil, ^(ThenParams)
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
   }).onProgress(^(float progress)
      {
         if(weakSelf)
         {
            weakSelf.progressBlock(progress);
		 }
      })
	  .onSuccess(^(NSNumber *result)
      {
		 dispatch_async(dispatch_get_main_queue(), ^
		{
		    if(weakSelf)
            {
		       weakSelf.resultLabel.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
			}
		});
	  })
   .then(nil, ^(ThenParams)
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
   }).onProgress(^(float progress)
      {
		 if(weakSelf)
         {
            weakSelf.progressBlock(progress);
		 }
      })
      .onSuccess(^(NSNumber *result)
      {
		 dispatch_async(dispatch_get_main_queue(), ^
		{
			if(weakSelf)
            {
		       weakSelf.resultLabel.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
			}
		});
	  })
   .then(nil, ^(ThenParams)
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
   }).onProgress(^(float progress)
      {
		 if(weakSelf)
         {
            weakSelf.progressBlock(progress);
		 }
      })
	 .onSuccess(^(NSNumber *result)
	 {
		dispatch_async(dispatch_get_main_queue(), ^
		{
			if(weakSelf)
            {
			   weakSelf.resultLabel.text = [NSString stringWithFormat:@"%ld", [result integerValue]];
			   weakSelf.startBTN.enabled = YES;
			}
		});
	 });
}


@end
