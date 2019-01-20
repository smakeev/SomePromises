//
//  ClassBoxTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 13/06/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ClassBoxTestViewController.h"
#import "SomePromise.h"

@interface TestModel : NSObject
{
   SomePromiseThread *_thread;
   NSTimer *_timer;
}
@property (nonatomic) SomeClassBox<NSNumber*> *i;

@end

@implementation TestModel

- (instancetype)init
{
   self = [super init];
   if(self)
   {
      self.i = [[SomeClassBox alloc] initWithValue:@(0)];
      _thread = [SomePromiseThread threadWithName:@"SomeClassBoxTestThread"];
	   __weak TestModel *weakSelf = self;
      _timer = [_thread scheduledTimerWithTimeInterval:1
                                               repeats:YES
                                                 block:^(NSTimer *timer)
                                                 {
													 TestModel *strongSelf = weakSelf;
													 if(strongSelf)
													 {
                                                        NSInteger i = strongSelf.i.value.integerValue;
                                                        i++;
                                                        strongSelf.i.value = @(i);
													 }
                                                 }];
   }
   return self;
}

- (void) dealloc
{
   [_timer invalidate];
   [_thread stop];
}

@end

@interface SomeClassBoxTestViewController ()
{
  TestModel *_model;
}
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation SomeClassBoxTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _model = [[TestModel alloc] init];
    _model.i.bind(self, ^(NSNumber *i)
    {
		dispatch_async(dispatch_get_main_queue(), ^{
			self->_label.text = [NSString stringWithFormat:@"%ld", i.integerValue];
        });
	});
}




@end
