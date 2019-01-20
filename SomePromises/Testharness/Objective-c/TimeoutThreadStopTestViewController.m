//
//  TimeoutThreadStopTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 14/05/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "TimeoutThreadStopTestViewController.h"
#import "SomePromise.h"

@interface TimeoutThreadStopTestViewController ()
{
   SomePromise *_promise;
   SomePromiseThread *_thread;
}
@property (weak, nonatomic) IBOutlet UIButton *startPromiseBtn;
@property (weak, nonatomic) IBOutlet UIButton *setTimeoutBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopThread;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation TimeoutThreadStopTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    _thread = [SomePromiseThread threadWithName:@"timeot_stop_test_thread"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startProise:(id)sender {
   self.resultLabel.text = @"Result";
   _promise = [SomePromise promiseWithName:@"testPromise" onThread:_thread resolvers:^(FulfillBlock fulfill, RejectBlock reject, IsRejectedBlock isRejected, ProgressBlock progress) {
	   					     for(int i = 0; i < 100; ++i)
						     {
						         guard (!isRejected()) else {return;}
						         sleep(1);
						         progress(i);
							 }
							 fulfill(Void);
       } class:nil];
	
       self.startPromiseBtn.enabled = NO;
	   __weak TimeoutThreadStopTestViewController *weakSelf = self;
       [_promise addOnSuccess:^(id result) {
			  weakSelf.startPromiseBtn.enabled = YES;
			  weakSelf.resultLabel.text = @"Success";
       }];
	
	   [_promise addOnReject:^(NSError *error) {
		   weakSelf.startPromiseBtn.enabled = YES;
		   weakSelf.resultLabel.text = error.description;
		   
       }];
	
       [_promise addOnProgress:^(float progress)
       {
			weakSelf.resultLabel.text = [NSString stringWithFormat:@"%f%%", progress];
	   }];
	
        [_promise addObserversQueue:dispatch_get_main_queue()];
	
}
   
- (IBAction)settimeout:(id)sender {
     [_promise addTimeout:10];
}

- (IBAction)restartThread:(id)sender {
  [_thread restart];
}


@end
