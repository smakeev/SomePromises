//
//  RetryTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 14/06/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "RetryTestViewController.h"
#import "SomePromise.h"

@interface RetryTestViewController ()
{
	__weak IBOutlet UILabel *_label1;
	__weak IBOutlet UILabel *_label2;
	__weak IBOutlet UILabel *_label3;
	__weak IBOutlet UIButton *_buttonStart;
	__weak IBOutlet UIButton *rejectButton;
	__weak IBOutlet UIButton *_thenTestButton;
	__weak IBOutlet UIButton *_whenTestButton;
	__weak IBOutlet UIButton *_whileBtn;
	__weak IBOutlet UIButton *_whileThenBtn;
	__weak IBOutlet UIButton *_whileWhenBtn;
	__weak IBOutlet UIButton *_infinityBtn;
	__weak IBOutlet UIButton *_infinityThenBtn;
	__weak IBOutlet UIButton *_infinityWhileBtn;
	int _atempt;
	SomePromise *_promise;
}
@end

@implementation RetryTestViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    rejectButton.enabled = NO;
}

- (BOOL)success
{
   _atempt += 1;
   return _atempt == 4;
}

- (void) setTextToCurrentLabel:(NSString*)text
{
       UILabel *current = nil;
       _label1.text = @"Label";
       _label2.text = @"Label";
       _label3.text = @"Label";
       switch(self->_atempt % 3)
       {
         case 0: current = self->_label1; break;
         case 1: current = self->_label2; break;
         case 2: current = self->_label3;
      }
	
      current.text = text;
}

- (IBAction)reject:(id)sender
{
   __weak RetryTestViewController *weakSelf = self;
   _promise.onReject(^(NSError *error){
      __strong RetryTestViewController *strongSelf = weakSelf;
      strongSelf->rejectButton.enabled = NO;
      strongSelf->_buttonStart.enabled = YES;
	  strongSelf->_thenTestButton.enabled = YES;
      strongSelf->_whenTestButton.enabled = YES;
	  strongSelf->_whileBtn.enabled = YES;;
	  strongSelf->_whileThenBtn.enabled = YES;;
	  strongSelf->_whileWhenBtn.enabled = YES;;
	  strongSelf->_infinityBtn.enabled = YES;;
	  strongSelf->_infinityThenBtn.enabled = YES;;
	  strongSelf->_infinityWhileBtn.enabled = YES;;
   });
   [_promise rejectAllInChain];
}

- (IBAction)start:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
				    for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
				}
                class:nil].onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
						 strongSelf->_whileBtn.enabled = YES;;
	                     strongSelf->_whileThenBtn.enabled = YES;;
	                     strongSelf->_whileWhenBtn.enabled = YES;;
	                     strongSelf->_infinityBtn.enabled = YES;;
	                     strongSelf->_infinityThenBtn.enabled = YES;;
	                     strongSelf->_infinityWhileBtn.enabled = YES;;

					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retry(4).onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
                        strongSelf->_whileBtn.enabled = YES;
	                    strongSelf->_whileThenBtn.enabled = YES;
	                    strongSelf->_whileWhenBtn.enabled = YES;;
						strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;
					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)thenTest:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
                   fulfillBlock(Void);
				}
                class:nil].then(nil, ^(ThenParams){
					for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
                }).onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
						 strongSelf->_whileBtn.enabled = YES;
	                     strongSelf->_whileThenBtn.enabled = YES;
	                     strongSelf->_whileWhenBtn.enabled = YES;
	                     strongSelf->_infinityBtn.enabled = YES;
	                     strongSelf->_infinityThenBtn.enabled = YES;
	                     strongSelf->_infinityWhileBtn.enabled = YES;
						 
					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retry(3).onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
	                    strongSelf->_whileBtn.enabled = YES;;
	                    strongSelf->_whileThenBtn.enabled = YES;;
	                    strongSelf->_whileWhenBtn.enabled = YES;;
	                    strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;
					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)whenTest:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
				   sleep(4);
                   fulfillBlock(Void);
				}
                class:nil].when(nil, ^(StdBlocks){
					for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					fulfillBlock(Void);
                }, ^(ResultParams){
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
				}).onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
	                     strongSelf->_whileBtn.enabled = YES;;
	                     strongSelf->_whileThenBtn.enabled = YES;;
	                     strongSelf->_whileWhenBtn.enabled = YES;;
	                     strongSelf->_infinityBtn.enabled = YES;;
	                     strongSelf->_infinityThenBtn.enabled = YES;;
	                     strongSelf->_infinityWhileBtn.enabled = YES;;

					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retry(3).onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
	                    strongSelf->_whileBtn.enabled = YES;;
	                    strongSelf->_whileThenBtn.enabled = YES;;
						strongSelf->_whileWhenBtn.enabled = YES;;
	                    strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;

					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)while:(id)sender
{
  _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
				    for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
				}
                class:nil].onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
						 strongSelf->_whileBtn.enabled = YES;;
	                     strongSelf->_whileThenBtn.enabled = YES;;
	                     strongSelf->_whileWhenBtn.enabled = YES;;
	                     strongSelf->_infinityBtn.enabled = YES;;
	                     strongSelf->_infinityThenBtn.enabled = YES;;
	                     strongSelf->_infinityWhileBtn.enabled = YES;;

					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retryWhile(CONDITION(self->_atempt < 4)).onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
                        strongSelf->_whileBtn.enabled = YES;
	                    strongSelf->_whileThenBtn.enabled = YES;
	                    strongSelf->_whileWhenBtn.enabled = YES;;
						strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;
					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)whileThen:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
                   fulfillBlock(Void);
				}
                class:nil].then(nil, ^(ThenParams){
					for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
                }).onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
						 strongSelf->_whileBtn.enabled = YES;
	                     strongSelf->_whileThenBtn.enabled = YES;
	                     strongSelf->_whileWhenBtn.enabled = YES;
	                     strongSelf->_infinityBtn.enabled = YES;
	                     strongSelf->_infinityThenBtn.enabled = YES;
	                     strongSelf->_infinityWhileBtn.enabled = YES;
						 
					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retryWhile(CONDITION(self->_atempt < 4)).onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
	                    strongSelf->_whileBtn.enabled = YES;;
	                    strongSelf->_whileThenBtn.enabled = YES;;
	                    strongSelf->_whileWhenBtn.enabled = YES;;
	                    strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;
					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)whileWhen:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
				   sleep(4);
                   fulfillBlock(Void);
				}
                class:nil].when(nil, ^(StdBlocks){
					for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					fulfillBlock(Void);
                }, ^(ResultParams){
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
				}).onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
	                     strongSelf->_whileBtn.enabled = YES;;
	                     strongSelf->_whileThenBtn.enabled = YES;;
	                     strongSelf->_whileWhenBtn.enabled = YES;;
	                     strongSelf->_infinityBtn.enabled = YES;;
	                     strongSelf->_infinityThenBtn.enabled = YES;;
	                     strongSelf->_infinityWhileBtn.enabled = YES;;

					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retryWhile(CONDITION(self->_atempt < 4)).onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
	                    strongSelf->_whileBtn.enabled = YES;;
	                    strongSelf->_whileThenBtn.enabled = YES;;
						strongSelf->_whileWhenBtn.enabled = YES;;
	                    strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;

					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)infinity:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
				    for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
				}
                class:nil].onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
						 strongSelf->_whileBtn.enabled = YES;;
	                     strongSelf->_whileThenBtn.enabled = YES;;
	                     strongSelf->_whileWhenBtn.enabled = YES;;
	                     strongSelf->_infinityBtn.enabled = YES;;
	                     strongSelf->_infinityThenBtn.enabled = YES;;
	                     strongSelf->_infinityWhileBtn.enabled = YES;;

					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retryInfinity.onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
                        strongSelf->_whileBtn.enabled = YES;
	                    strongSelf->_whileThenBtn.enabled = YES;
	                    strongSelf->_whileWhenBtn.enabled = YES;;
						strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;
					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)infinityThen:(id)sender
{
   _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
                   fulfillBlock(Void);
				}
                class:nil].then(nil, ^(ThenParams){
					for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
                }).onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
						 strongSelf->_whileBtn.enabled = YES;
	                     strongSelf->_whileThenBtn.enabled = YES;
	                     strongSelf->_whileWhenBtn.enabled = YES;
	                     strongSelf->_infinityBtn.enabled = YES;
	                     strongSelf->_infinityThenBtn.enabled = YES;
	                     strongSelf->_infinityWhileBtn.enabled = YES;
						 
					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retryInfinity.onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
	                    strongSelf->_whileBtn.enabled = YES;;
	                    strongSelf->_whileThenBtn.enabled = YES;;
	                    strongSelf->_whileWhenBtn.enabled = YES;;
	                    strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;
					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

- (IBAction)infinityWhen:(id)sender
{
      _atempt = 0;
   _label1.text = @"Label";
   _label2.text = @"Label";
   _label3.text = @"Label";
   _buttonStart.enabled = NO;
   _thenTestButton.enabled = NO;
   _whenTestButton.enabled = NO;
   _whileBtn.enabled = NO;;
   _whileThenBtn.enabled = NO;;
   _whileWhenBtn.enabled = NO;;
   _infinityBtn.enabled = NO;;
   _infinityThenBtn.enabled = NO;;
   _infinityWhileBtn.enabled = NO;;

   rejectButton.enabled = YES;
   __weak RetryTestViewController *weakSelf = self;
   _promise = [SomePromise promiseWithName:@"Retry Test Promise"
                resolvers:^(StdBlocks)
                {
				   sleep(4);
                   fulfillBlock(Void);
				}
                class:nil].when(nil, ^(StdBlocks){
					for(int i = 0; i < 3; ++i)
					{
					   sleep(1);
					}
					fulfillBlock(Void);
                }, ^(ResultParams){
					if([weakSelf success])
					{
					   fulfillBlock(Void);
					}
					else
					{
					   rejectBlock(nil);
					}
				}).onSuccess(^(NoResult)
                {
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         __strong RetryTestViewController *strongSelf = weakSelf;
					     strongSelf->_buttonStart.enabled = YES;
						 strongSelf->_thenTestButton.enabled = YES;
                         strongSelf->_whenTestButton.enabled = YES;
	                     strongSelf->_whileBtn.enabled = YES;;
	                     strongSelf->_whileThenBtn.enabled = YES;;
	                     strongSelf->_whileWhenBtn.enabled = YES;;
	                     strongSelf->_infinityBtn.enabled = YES;;
	                     strongSelf->_infinityThenBtn.enabled = YES;;
	                     strongSelf->_infinityWhileBtn.enabled = YES;;

					     [strongSelf setTextToCurrentLabel:@"SUCCESS"];
					 });
				}).onReject(^(NSError *error)
				{
				    dispatch_async(dispatch_get_main_queue(), ^
				    {
				         __strong RetryTestViewController *strongSelf = weakSelf;
					    [strongSelf setTextToCurrentLabel:@"REJECTED"];
					});
				}).retryInfinity.onReject(^(NSError *error)
				{
				     dispatch_async(dispatch_get_main_queue(), ^
				     {
				         __strong RetryTestViewController *strongSelf = weakSelf;
						[strongSelf setTextToCurrentLabel:@"NO MORE ATEMPTS"];
						strongSelf->_buttonStart.enabled = YES;
						strongSelf->_thenTestButton.enabled = YES;
                        strongSelf->_whenTestButton.enabled = YES;
	                    strongSelf->_whileBtn.enabled = YES;;
	                    strongSelf->_whileThenBtn.enabled = YES;;
						strongSelf->_whileWhenBtn.enabled = YES;;
	                    strongSelf->_infinityBtn.enabled = YES;;
	                    strongSelf->_infinityThenBtn.enabled = YES;;
	                    strongSelf->_infinityWhileBtn.enabled = YES;;

					 });
				}).onSuccess(^(NoResult){
				   NSLog(@"SUCCESS");
				}).thenOnMain(nil, ^(ThenParams){
				    __strong RetryTestViewController *strongSelf = weakSelf;
				    strongSelf->rejectButton.enabled = NO;
				});
}

@end
