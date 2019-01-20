//
//  SettingsTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 08/06/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SettingsTestViewController.h"
#import "SomePromise.h"

@interface SettingsTestViewController ()
{
   SomePromise *_promise;
   SomePromise *_whenPromise;
   SomePromise *_dependantPromise;
   __weak IBOutlet UIButton *_startButton;
   __weak IBOutlet UIButton *_whenButton;
   __weak IBOutlet UIButton *dependantButton;
}

@end

@implementation SettingsTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)start:(id)sender
{
   _startButton.enabled = NO;
	
   if(_promise == nil)
   {
      _promise =  [SomePromise promiseWithName:@"promise for settings test"
													   onQueue:nil
													  delegate:nil
												 delegateQueue:nil
													 resolvers:^(BaseBlocks(fulfillBlock, rejectBlock))
								   {
									   for(int i = 0; i < 10; ++i)
									   {
										   sleep(1);
									   }
									   fulfillBlock(@(1000));
								   } class: NSNumber.class].onSuccess(^(id result){
								      dispatch_async(dispatch_get_main_queue(), ^{
	                                      self->_startButton.enabled = YES;
	                                      NSLog(@"Result: %@", result);
								      });
								   });
   }
   else
   {
      SomePromiseSettings *settings = [_promise.settings freshCopy];
	  [SomePromise promiseWithSettings:settings].onSuccess(^(id result){ NSLog(@"OK");});
   }
}

- (IBAction)when:(id)sender
{
	_whenButton.enabled = NO;
	if(_whenPromise == nil)
	{
	     _whenPromise = [SomePromise promiseWithName:@"promise for When settings test"
											 onQueue:nil
											delegate:nil
									   delegateQueue:nil
										   resolvers:^(BaseBlocks(fulfillBlock, rejectBlock))
						{
						   for(int i = 0; i < 10; ++i)
						   {
							  sleep(1);
						   }
							  fulfillBlock(@(2000));
						} class: NSNumber.class].whenWithName(@"When settings promise", NSNumber.class, ^(StdBlocks)
						                         {
						                              fulfillBlock(@"100");
								                 }, ^(ResultParams)
								                 {
							                        fulfillBlock(@([result integerValue] * 10));
						}).onSuccess(^(id result){
						    dispatch_async(dispatch_get_main_queue(), ^{
						        self->_whenButton.enabled = YES;
								NSLog(@"When Result: %@", result);
                            });
						});
	}
	else
	{
	    SomePromiseSettings *settings = [_whenPromise.settings freshCopy];
	    _whenPromise = [SomePromise promiseWithSettings:settings];
	}
}

- (IBAction)dependant:(id)sender
{
   dependantButton.enabled = NO;
   if(_dependantPromise == nil)
   {
       _dependantPromise = [SomePromise promiseWithName:@"promise for When settings test"
												onQueue:nil
											   delegate:nil
										  delegateQueue:nil
										      resolvers:^(BaseBlocks(fulfillBlock, rejectBlock))
						{
						   for(int i = 0; i < 10; ++i)
						   {
							  sleep(1);
						   }
							  fulfillBlock(@(2000));
						} class: NSNumber.class].thenElseWithName(@"Dependant Settings test", NSNumber.class,^(ThenParams){fulfillBlock(@(3000));}, ^(ElseParams){
						     fulfillBlock(@(4000));
					    }).onSuccess(^(id result){
						    dispatch_async(dispatch_get_main_queue(), ^{
						        self->dependantButton.enabled = YES;
								NSLog(@"depend Result: %@", result);
                            });
						});
  }
  else
  {
      SomePromiseSettings *settings = [_dependantPromise.settings freshCopy];
	  _dependantPromise = [SomePromise promiseWithSettings:settings];
  }
}


@end
