//
//  ForthTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 03/02/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ForthTestViewController.h"
#import "SomePromise.h"

@interface ForthTestViewController ()
{
    SomePromise *_promise;
	
	
	__weak IBOutlet UIButton *startBtn;
	
	__weak IBOutlet UILabel *resultLabel;
	__weak IBOutlet UIButton *rejectBtn;
}
@end

@implementation ForthTestViewController
- (IBAction)reject:(id)sender
{
   [_promise reject];
}

- (IBAction)startTest:(id)sender
{
    startBtn.enabled = NO;
    rejectBtn.enabled = YES;
	_promise =	[[[[SomePromise promiseWithName:@"4 test promise"
					 resolvers:^(AllBlocksWithNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock))
					 {
						     for(int i = 0; i < 100; ++i)
						     {
						         sleep(1);
						         progressBlock(i);
						         if(isRejectedBlock())
						         {
						            return;
								 }
							 }
							 fulfillBlock(Void);
					 } class: nil] onSuccess:^(NoResult)
					 {
						dispatch_async(dispatch_get_main_queue(), ^
						{
							self->resultLabel.text = @"SUCCESS";
							self->startBtn.enabled = YES;
							self->rejectBtn.enabled = NO;
                        });
					 }] onReject:^(NSError *error)
					 {
						dispatch_async(dispatch_get_main_queue(), ^
						{
							self->resultLabel.text = @"REJECTED";
							self->startBtn.enabled = YES;
							self->rejectBtn.enabled = NO;
                        });
					 }] onProgress:^(float progress)
					 {
						dispatch_async(dispatch_get_main_queue(), ^
						{
							self->resultLabel.text = [NSString stringWithFormat:@"%f%%", progress];
                        });
					 }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    rejectBtn.enabled = NO;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [_promise reject];
    _promise = nil;
    [super viewWillDisappear:animated];
}

@end
