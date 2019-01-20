//
//  ThirdTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 24/01/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ThirdTestViewController.h"
#import "SomePromise.h"

@interface ThirdTestViewController ()
{
     UIViewPropertyAnimator *_viewMoveAnimator;
     IBOutlet __weak UIView *_viewToMove;
     SomePromise *_mainPromise;
     BOOL started;
}
@end

@implementation ThirdTestViewController


- (void) animatorPreparer:(CGPoint) location
{
	_viewMoveAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:3 curve:UIViewAnimationCurveEaseInOut animations:^
	{
		self->_viewToMove.center = location;
	}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_viewToMove.layer.cornerRadius = _viewToMove.frame.size.width / 2;
}

- (void)viewWillDisappear:(BOOL)animated
{
   [_mainPromise rejectAllDependences];
   [_mainPromise reject];
   [super viewWillDisappear:animated];
}

- (IBAction)create:(id)sender
{
    _mainPromise = [SomePromise postpondedPromiseWithName:@"Maint_Promise_Test3"
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
						 dispatch_sync(dispatch_get_main_queue(), ^{
							 if(self->_viewToMove.center.x < self.view.frame.size.width - self->_viewToMove.frame.size.width / 2)
							 {
								 [self animatorPreparer:CGPointMake(self.view.frame.size.width - self->_viewToMove.frame.size.width / 2, self->_viewToMove.center.y)];
							 }
							 else
							 {
								 [self animatorPreparer:CGPointMake(self->_viewToMove.frame.size.width / 2, self->_viewToMove.center.y)];
							 }
							 
							 [self->_viewMoveAnimator addCompletion:^(UIViewAnimatingPosition finalPosition)
							  {
								  FulfillBlock(Void);
								  self->_viewMoveAnimator = nil;
							  }];
							 [self->_viewMoveAnimator startAnimation];
						 });
					 } class: nil];
}

- (IBAction)start:(id)sender
{
	[_mainPromise start];
}

- (IBAction)rejectMain:(id)sender
{
    if (ESomePromisePending != _mainPromise.status)
    {
		return;
	}
	[_viewMoveAnimator stopAnimation:YES];
	[_mainPromise reject];
}


- (void) horizontalCaseFuture:(FulfillBlock _Nonnull)futureBlock noFuture:(RejectBlock _Nullable) rejectBlock
{
	dispatch_sync(dispatch_get_main_queue(), ^{
		if(self->_viewToMove.center.y < (self.view.frame.size.height - 45) - self->_viewToMove.frame.size.height / 2)
							 {
								 [self animatorPreparer:CGPointMake(self->_viewToMove.center.x, self.view.frame.size.height - self->_viewToMove.frame.size.height / 2)];
							 }
							 else
							 {
								 [self animatorPreparer:CGPointMake(self->_viewToMove.center.x, 45 + self->_viewToMove.frame.size.height / 2)];
							 }
		
		[self->_viewMoveAnimator addCompletion:^(UIViewAnimatingPosition finalPosition)
							  {
								  futureBlock(Void);
								  self->_viewMoveAnimator = nil;
							  }];
		[self->_viewMoveAnimator startAnimation];
						 });
}

- (IBAction)addHorizontalDependence:(id)sender //in all cases do
{
    [SomePromise promiseWithName:@"VerticalDependance"
                     dependentOn:_mainPromise
                       onSuccess:^(BaseBlocks(fulfill, reject), NoResult, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                       {
		                  [self horizontalCaseFuture:fulfill noFuture:reject];
                       }
                       onReject:^(BaseBlocks(fulfill, reject), NSError *error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
                       {
                          [self horizontalCaseFuture:fulfill noFuture:reject];
                       } class: nil];
}

- (void) colorCaseFuture:(FulfillBlock _Nonnull)futureBlock isRejected:(IsRejectedBlock _Nullable) rejectBlock
{
	__block UIColor *initialColor = nil;
	if (rejectBlock())
	{
	   return;
	}
	dispatch_async(dispatch_get_main_queue(), ^
				   {
					   initialColor = self->_viewToMove.backgroundColor;
					   self->_viewToMove.backgroundColor = UIColor.greenColor;
				   });
	sleep(2);
	if (rejectBlock())
	{
	   return;
	}
	dispatch_async(dispatch_get_main_queue(), ^
				   {
					   self->_viewToMove.backgroundColor = UIColor.yellowColor;
				   });
	sleep(2);
	if (rejectBlock())
	{
	   return;
	}
	dispatch_async(dispatch_get_main_queue(), ^
				   {
					   self->_viewToMove.backgroundColor = UIColor.redColor;
				   });
	sleep(2);
	if (rejectBlock())
	{
	   return;
	}
	dispatch_async(dispatch_get_main_queue(), ^
				   {
					   self->_viewToMove.backgroundColor = UIColor.blueColor;
				   });
	sleep(2);
	if (rejectBlock())
	{
	   return;
	}
	dispatch_async(dispatch_get_main_queue(), ^
				   {
					   self->_viewToMove.backgroundColor = initialColor;
					   futureBlock(Void);
				   });
}

- (IBAction)addColorDependence:(id)sender //only in success
{
    [SomePromise promiseWithName:@"ColorDependance"
                     dependentOn:_mainPromise
         onSuccess:^(RejectedCheckBlocks(fulfill, reject, isRejected), NoResult, id<SomePromiseLastValuesProtocol> lastValuesInChain)
         {
		    [self colorCaseFuture:fulfill isRejected:isRejected];
         }
         onReject:^(BaseBlocks(fulfill, reject), NSError *error, id<SomePromiseLastValuesProtocol> lastValuesInChain)
         {
             reject(error);
         } class: nil];
}

- (IBAction)rejectColorDependence:(id)sender
{
  [_mainPromise rejectDependenceByRule:^BOOL(SomePromise * _Nonnull promise) {
      return [promise.name isEqualToString:@"ColorDependance"];
  }];
}

- (IBAction)rejectVerticalDependence:(id)sender
{
   [_mainPromise rejectDependencesWithName:@"VerticalDependance"];
}

- (IBAction)rejectAllDependences:(id)sender
{
  [_mainPromise rejectAllDependences];
}

- (IBAction)addWhenToMain:(id)sender
{
  [SomePromise promiseWithName: @"WhenPromise"
				   whenPromise: _mainPromise
					 resolvers: ^(BaseBlocks(fulfill, reject))
					 {
					     __block UIColor *prevColor = UIColor.whiteColor;
						 for (int i = 0; i < 10; ++i)
						 {
							 dispatch_sync(dispatch_get_main_queue(), ^
											{
												if ([self->_viewToMove.backgroundColor isEqual:UIColor.whiteColor])
												{
													self->_viewToMove.backgroundColor = prevColor;
												}
												else
												{
													prevColor = self->_viewToMove.backgroundColor;
													self->_viewToMove.backgroundColor = UIColor.whiteColor;
												}
											});
							 sleep(1);
						 }
						 fulfill(Void);
					 }
				     finalResult:^(BaseBlocks(fulfill, reject), id ownerResult, id selfResult, NSError *ownerError, NSError *selfError, id<SomePromiseLastValuesProtocol> lastValuesInChain)
				     {
						 fulfill(Void);
					 } class: nil];
}

@end
