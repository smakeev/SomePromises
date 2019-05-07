//
//  MainScreenControllerViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 15/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "MainScreenControllerViewController.h"
#import "ListsNewsContainerViewController.h"
#import "NewsWebPresentationViewController.h"
#import "AlertsPresenterProtocolStrategy.h"
#import "ContainerableProtocolStrategy.h"

#import "NewsOptionsViewController.h"

typedef NS_ENUM(NSInteger, ControllerState)
{
	EBoth = 0,
	ELeft = 1,
	ERight = 2,
};

@interface MainScreenControllerViewController () <AlertsPresenterProtocol>
{
	BOOL _leftContainerInitialized;
	BOOL _rightContainerInitialized;
	BOOL _hasWebContentNow;
	NewsOptionsViewController *_optionsPresenter;
	
	__weak IBOutlet NSLayoutConstraint *_leftContainerWidthConstraint1;
	__weak IBOutlet NSLayoutConstraint *_leftContainerWidthConstraint2;
	__weak IBOutlet NSLayoutConstraint *_leftContainerFullWidth;
	
	__weak IBOutlet NSLayoutConstraint *_rightConrollerFullWidth1;
	
	
	ControllerState _currentState;
}

@property (weak, nonatomic) IBOutlet UIView *leftContainerView;
@property (weak, nonatomic) IBOutlet UIView *rightContainerView;

@end

@implementation MainScreenControllerViewController
@synthesize container;
@synthesize embededControllers;

//@TODO:
- (UIView*) baseAlertView
{
	return nil;
}


+ (void) load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(AlertsPresenterProtocol) extention:[AlertsPresenterProtocolStrategy class] whereSelf:@protocol(NSObject)];
		[SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(Containerable) extention:[ContainerableProtocolStrategy class] whereSelf:@protocol(NSObject)];
	});
}

- (void)viewDidLoad {
	[super viewDidLoad];
	embededControllers = [SPArray new];
	if(self.leftController && !_leftContainerInitialized)
	{
		[self setupLeftContainer];
	}
	
	if(self.rightController && !_rightContainerInitialized)
	{
		[self setupRightContainer];
	}
	_optionsPresenter = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NewsOptionsController"];

	UIView *subView = _optionsPresenter.view;
	[_optionsPresenter willMoveToParentViewController:self];
	
	[self.view addSubview:subView];

	subView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view   addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subView)]];
	[self.view  addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subView)]];
	
	[_optionsPresenter didMoveToParentViewController:self];
}

- (void) setLeftController:(ListsNewsContainerViewController *)leftController
{
	if (self.leftController)
		return;
	
	_leftController = leftController;
	if(!_leftContainerInitialized)
		[self setupLeftContainer];
}

- (void) setupLeftContainer
{
	guard (self.leftController && !_leftContainerInitialized && self.leftContainerView) else {return;}
	if ([self setupContainer:self.leftController inView:self.leftContainerView])
	{
		_leftContainerInitialized = YES;
	}
	[self.embededControllers addWeakly:self.leftController];
}

- (void) setRightController:(NewsWebPresentationViewController *)rightController
{
	if (self.rightController)
		return;
	
	_rightController = rightController;
	if(!_rightContainerInitialized)
		[self setupRightContainer];
}

- (void) setupRightContainer
{
	guard (self.rightController && !_rightContainerInitialized && self.rightContainerView) else {return;}
	
	if ([self setupContainer:self.rightController inView:self.rightContainerView])
	{
		_rightContainerInitialized = YES;
	}
	[self.embededControllers addWeakly:self.rightController];
}

- (BOOL) setupContainer:(UIViewController<Containerable>*)controller inView:(UIView*)targetView
{
	UIView *subView = controller.view;
	[controller willMoveToParentViewController:self];
	[targetView addSubview:subView];
	subView.translatesAutoresizingMaskIntoConstraints = NO;
	[targetView  addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subView)]];
	[targetView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subView)]];
	
	[controller didMoveToParentViewController:self];
	controller.container = self;
	
	return YES;
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	if(_currentState != EBoth)
	{
		_currentState = EBoth;
		[self sendStateChanged];
	}
	[self updateRightContainerVisibility];
}

- (void) updateRightContainerVisibility
{
	if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && !_hasWebContentNow)
	{
		if(self.rightContainerView.hidden == NO)
		{
			
			[UIView animateWithDuration:0.5 animations:^{
				self.rightContainerView.alpha = 0;
			} completion:^(BOOL finished) {
				self.rightContainerView.alpha = 1;
				self.rightContainerView.hidden = YES;
			}];
		}
	}
	else
	{
		if(self.rightContainerView.hidden == YES && _currentState != ELeft)
		{
			self.rightContainerView.alpha = 0;
			self.rightContainerView.hidden = NO;
			[UIView animateWithDuration:0.5 animations:^{
				self.rightContainerView.alpha = 1;
			}];
		}
	}
}

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{
	if([signal.name isEqualToString:selectArticle])
	{
		return YES;
	}
	if([signal.name isEqualToString:unselectArticle])
	{
		return YES;
	}
	if([signal.name isEqualToString:optionsPressed])
	{
		return YES;
	}
	if([signal.name isEqualToString:sizeChangingAsked])
	{
		return YES;
	}
	
	if([signal.name isEqualToString:hideOptions])
	{
		return YES;
	}
	
	if([signal.name isEqualToString:showOptions])
	{
		return YES;
	}
	
	return NO;
}

 - (void)handleTheSignal:(SomePromiseSignal*)signal
 {
 	if([signal.name isEqualToString:showOptions])
 	{
		if (_optionsPresenter.view.hidden) {
			_optionsPresenter.view.hidden = NO;
		}
 		return;
	}
 
 	if([signal.name isEqualToString:hideOptions])
 	{
 		if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact || _currentState == ELeft) {
			if (!_optionsPresenter.view.hidden) {
				_optionsPresenter.view.hidden = YES;
			}
		}
 		return;
	}
 
 	if([signal.name isEqualToString:optionsPressed])
 	{
		_optionsPresenter.view.hidden = !_optionsPresenter.view.hidden;
 		return;
	}

	if([signal.name isEqualToString:sizeChangingAsked])
	{
		[self onSizeChanger:signal];
		[super handleTheSignal:signal];
		return;
	}

 	if([signal.name isEqualToString:selectArticle])
 	{
		_hasWebContentNow = [signal.message[@"articleID"] integerValue] >= 0 ? YES : NO;
		if(_hasWebContentNow)
		{
			[self setState:EBoth fromSignal:NO];
		}
	}
	if([signal.name isEqualToString:unselectArticle])
	{
		_hasWebContentNow = NO;
		if(_currentState == ERight)
		{
			[self setState:EBoth fromSignal:NO];
		}
	}
	[self updateRightContainerVisibility];
	
 }

- (void) sendStateChanged
{
		NSString *stateString;
		switch(_currentState)
		{
			case EBoth:
				stateString = @"Both";
				break;
			case ELeft:
				stateString = @"Left";
				break;
			case ERight:
				stateString = @"Right";
				break;
		}
		SomePromiseSignal *screenChangedSignal = [[SomePromiseSignal alloc] initWithName:mainScreenChangedSignal tag:0 message:@{@"state" : stateString} anythingElse:nil];
		NSMutableSet *receivers = [NSMutableSet new];
		[self getAllReceiversForController:self set:receivers];
		[receivers removeObject:self];
		[self sendSignal:screenChangedSignal toObject:receivers.allObjects];
}

- (void) setState:(ControllerState)state fromSignal:(BOOL)fromSignal
{
	if(_currentState == state)
	{
		return;
	}
	_currentState = state;
	switch(state)
	{
		case EBoth:
			_leftContainerWidthConstraint1.active = YES;
			_leftContainerWidthConstraint2.active = YES;
			_leftContainerFullWidth.active = NO;
			_rightConrollerFullWidth1.active = NO;
			break;
		case ELeft:
			_leftContainerWidthConstraint1.active = NO;
			_leftContainerWidthConstraint2.active = NO;
			_leftContainerFullWidth.active = YES;
			_rightConrollerFullWidth1.active = NO;
			break;
		case ERight:
			_leftContainerWidthConstraint2.active = NO;
			_leftContainerFullWidth.active = NO;
			_rightConrollerFullWidth1.active = YES;
			break;
	}
	
	if(self->_currentState == EBoth && self.rightContainerView.hidden)
	{
		self.rightContainerView.hidden = NO;
		self.rightContainerView.alpha = 0;
	}
	
	[UIView animateWithDuration:0.5 animations:^{
		[self.view layoutIfNeeded];
		self.rightContainerView.alpha = self->_currentState != ELeft  ? 1 : 0;
	} completion:^(BOOL finished) {
		self.rightContainerView.hidden = self->_currentState != ELeft ? NO : YES;
		self.rightContainerView.alpha = 1;
	}];
	
	if(!fromSignal)
	{
		[self sendStateChanged];
	}
}

- (void) onSizeChanger:(SomePromiseSignal*)signal
{
	UIButton *button = signal.message[@"button"];
	if([signal.message[@"sender"] isEqualToString:@"leftController"])
	{
		if(_currentState == EBoth)
		{
			[self setState:ELeft fromSignal:YES];
			[button setImage:[UIImage imageNamed:@"minimize"] forState:UIControlStateNormal];
		}
		else
		{
			[self setState:EBoth fromSignal:YES];
			[button setImage:[UIImage imageNamed:@"extend"] forState:UIControlStateNormal];
		}
	}
	else
	{
		if(_currentState == EBoth)
		{
			[self setState:ERight fromSignal:YES];
			[button setImage:[UIImage imageNamed:@"minimize"] forState:UIControlStateNormal];
		}
		else
		{
			[self setState:EBoth fromSignal:YES];
			[button setImage:[UIImage imageNamed:@"extend"] forState:UIControlStateNormal];
		}
	}
}

@end
