//
//  MenuViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 10/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "MenuViewController.h"
#import "MenuView.h"
#import "AppDelegate.h"
#import "MenuModel.h"

@interface MenuViewController ()
{
	__weak IBOutlet UIView *_background;
	__weak IBOutlet MenuView *_menuView;
	__weak IBOutlet UIView *_menuTouchView;
	__weak IBOutlet UIView *_menuSpaceView;

	__weak IBOutlet NSLayoutConstraint *_menuSpaceWidth;
	__weak IBOutlet UISegmentedControl *_startFromSegmentedControl;
	
	__weak MenuModel *_modelMenu;
}

@property (nonatomic) BOOL menuShown;
@property (nonatomic) NSInteger menuShownPercent;

@property (weak, nonatomic) IBOutlet MenuView *menuView;

@end

@implementation MenuViewController

- (void) setMenuShownPercent:(NSInteger)menuShownPercent
{
	_menuShownPercent = menuShownPercent;
	CGFloat value = (CGFloat)_menuShownPercent / 100.0f;
	_background.alpha = value / 2.0f;
	if(value > 0)
	{
		_menuSpaceWidth.constant = _background.frame.size.width -menuShownPercent * _background.frame.size.width / 100;
	}
	else
	{
		_menuSpaceWidth.constant = _background.frame.size.width - 10;
	}
	[self.view layoutIfNeeded];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	//add pan gesture
	UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveMenu:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [_menuTouchView addGestureRecognizer:panRecognizer];
	
	@sp_avoidblockretain(self)
	@sp_startUI(sp_action(self, ^(NSValue *frame){
		@sp_strongify(self)
		guard(self) else {return;}
		//update constraint for menu offset
		if(!self->_menuShown)
		{
			self->_menuSpaceWidth.constant = self->_background.frame.size.width - 10;
		}
	})) = @sp_observe(_background, bounds);
	@sp_avoidend(self)
	
	_modelMenu = ((AppDelegate*)UIApplication.sharedApplication.delegate).modelMenu;
	_startFromSegmentedControl.selectedSegmentIndex = _modelMenu.startSearch;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if(!_menuShown)
	{
		[self hideMenu];
	}
	else
	{
		[self showMenu];
	}
}

- (void) moveMenu:(UIPanGestureRecognizer*)recognizer
{
	CGFloat _maxX = _menuView.superview.frame.size.width;
	CGPoint point = [recognizer locationInView:self.view];
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
	
		if(!_menuShown)
		{
			[_menuView makeVisible:YES];
		}
	}
	
	if(recognizer.state == UIGestureRecognizerStateChanged)
	{
		//calculate percent
		if(point.x < _maxX)
		{
			self.menuShownPercent = point.x * 100 / _maxX;
		}
	}
	
	if(recognizer.state == UIGestureRecognizerStateEnded)
	{
		if(self.menuShownPercent >= 50)
		{
			[self showMenu];
		}
		else
		{
			[self hideMenu];
		}
	}
	
	if(recognizer.state == UIGestureRecognizerStateCancelled)
	{
		if(_menuShown)
		{
			[self showMenu];
		}
		else
		{
			[self hideMenu];
		}
	}
}

- (void) showMenu
{
	[self->_menuView makeVisible:YES];
	[UIView animateWithDuration:0.5 animations:^{
		self.menuShownPercent = 100;
	} completion:^(BOOL finished) {
		self.menuShown = YES;
	}];
}

- (void) hideMenu
{
	[UIView animateWithDuration:0.5 animations:^{
		self.menuShownPercent = 0;
	}  completion:^(BOOL finished) {
		self.menuShown = NO;
		[self->_menuView makeVisible:NO];
	}];
}

- (IBAction)startSearchChanged:(UISegmentedControl*)sender {
	_modelMenu.startSearch = sender.selectedSegmentIndex;
}

@end
