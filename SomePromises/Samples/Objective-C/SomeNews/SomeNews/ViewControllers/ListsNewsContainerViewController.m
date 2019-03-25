//
//  ListsNewsContainerViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 15/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ListsNewsContainerViewController.h"
#import "NewsListViewController.h"
#import "MainScreenControllerViewController.h"
#import "AlertsPresenterProtocolStrategy.h"
#import "ContainerableProtocolStrategy.h"

#import "MenuViewController.h"
#import "ActionButton.h"

@protocol PopoverItemsProvider <NSObject>
- (UIButton*) locationItem;
- (UIButton*) localeItem;
@end

@interface ListsNewsContainerViewController (PopoverPresentationDelegate) <UIPopoverPresentationControllerDelegate>
@end

@interface ListsNewsContainerViewController () <AlertsPresenterProtocol, UITextFieldDelegate>
{
	SPPair<NewsListViewController*, NewsListViewController*> *_tableControllersPair;
	BOOL _isRightActive;
	BOOL _initialized;
	BOOL _findFieldActive;
	__weak IBOutlet UIButton *_findButton;
	__weak IBOutlet UIButton *_moreButton;
	__weak IBOutlet UITextField *_findTextField;
	__weak IBOutlet UIButton *_menuButton;

	__weak IBOutlet UIButton *_extendButton;
	__weak IBOutlet UIView *_textFieldContainer;
	__weak IBOutlet NSLayoutConstraint *_textFieldContainerConstraint;
	__weak IBOutlet NSLayoutConstraint *_findTextFieldTrailingConstraint;
	__weak IBOutlet NSLayoutConstraint *_findContainerTrailingForPlusInLandscapeConstraint;
	
	__weak IBOutlet UILabel *searchSring;
	MenuViewController *_menuPresenter;
	UIViewController<PopoverItemsProvider> *_locationPopoverController;
}

@property (weak, nonatomic) IBOutlet UIButton *flipButton;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topView;

@end

@implementation ListsNewsContainerViewController
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

- (void)viewDidLoad
{
	[super viewDidLoad];
	embededControllers = [SPArray new];
	if(!_initialized && _tableControllersPair.right && _tableControllersPair.left)
	{
		[self addTables];
	}
	
	_menuPresenter = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MenuController"];
	UIView *menuView = _menuPresenter.view;
	[_menuPresenter willMoveToParentViewController:self];
	[self.view addSubview:menuView];
	self.view.clipsToBounds = YES;
	menuView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view   addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_topView][menuView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_topView, menuView)]];
	[self.view  addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[menuView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(menuView)]];
	
	[_menuPresenter didMoveToParentViewController:self];
	
	@sp_avoidblockretain(self)
	@sp_startUI(sp_action(self, ^(NSNumber *percent){
		@sp_strongify(self)
		guard(self) else {return;}
		CGFloat angle = ((CGFloat)(percent.integerValue * 90.0f)) / 100.0f;
		[UIView animateWithDuration:0.5 animations:^{
			self->_menuButton.transform = CGAffineTransformMakeRotation(angle * M_PI / 180);
		}];
	})) = @sp_observe(_menuPresenter, menuShownPercent);
	@sp_avoidend(self)
	
	Services.user.state.bind(self, ^(NSString *search) {
		NSLog(@"!! Search for: %@", search);
		self->searchSring.text = search;
	});
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	_textFieldContainer.layer.cornerRadius = 16;
	_textFieldContainer.layer.masksToBounds = NO;
	_textFieldContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;
	
	_findTextField.delegate = self;
	
	[self.view bringSubviewToFront:self.flipButton.superview];
	[self.view bringSubviewToFront:self.flipButton];
	static dispatch_once_t onceToken;
	@sp_avoidblockretain(self);
	dispatch_once(&onceToken, ^{
		@sp_strongify(self)
		@sp_uibind(Services.user, querry) = @sp_observeTextField(self->_findTextField).filter(^(NSString *text){
			@sp_strongify(self)
			guard(self) else {return NO;}
			return self->_findFieldActive;
		});
		@sp_startUI(sp_action(self, ^(UITextField *textField){
			@sp_strongify(self)
			guard(self) else {return;}
			[((AppDelegate*)([UIApplication sharedApplication].delegate)) startUpdate];
			self->_findTextField.text = @"";
		})) = @sp_observeControl(self->_findTextField, UIControlEventEditingDidEnd);
		@sp_startUI(sp_action(self, ^(UITextField *textField){
			textField.text = Services.user.querry;
		})) = @sp_observeControl(self->_findTextField, UIControlEventEditingDidBegin);
	});
	@sp_avoidend(self)
}

- (void) addTables
{
	UIViewController<Containerable> *leftController = _tableControllersPair.left;
	UIViewController<Containerable> *rightController = _tableControllersPair.right;
	
	UIView *left = leftController.view;
	UIView *right = rightController.view;
	
	[leftController willMoveToParentViewController:self];
	[rightController willMoveToParentViewController:self];
	[self.containerView addSubview:left];
	[self.containerView addSubview:right];
	
	//adjusting.
	leftController.view.translatesAutoresizingMaskIntoConstraints = NO;
	rightController.view.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self.containerView  addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[left]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(left)]];
	[self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[left]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(left)]];
	
	[self.containerView  addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[right]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(right)]];
	[self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[right]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(right)]];
	
	[leftController didMoveToParentViewController:self];
	[rightController didMoveToParentViewController:self];
	
	_isRightActive = YES;
	_initialized = YES;
	[embededControllers addWeakly:leftController];
	[embededControllers addWeakly:rightController];
}

- (void) addTopController:(NewsListViewController*)controller
{
	if(!_tableControllersPair)
	{
		_tableControllersPair = [[SPPair alloc] init];
	}

	if(_tableControllersPair.right)
		return;
	_tableControllersPair.right = controller;
	controller.container = self;
	if (_tableControllersPair.left && !_initialized)
	{
		if(self.view) //force load view
		{
			//do nothing
		}
	}
}

- (void) addSectionsController:(NewsListViewController*)controller
{
	if(!_tableControllersPair)
	{
		_tableControllersPair = [[SPPair alloc] init];
	}

	if(_tableControllersPair.left)
		return;
	_tableControllersPair.left = controller;
	controller.container = self;
	if (_tableControllersPair.right && !_initialized)
	{
		if(self.view) //force load view
		{
			//do nothing
		}
	}

}

- (IBAction)flipPressed:(id)sender
{
	UIView *from = _isRightActive ? _tableControllersPair.right.view : _tableControllersPair.left.view;
	UIView *to = _isRightActive ? _tableControllersPair.left.view : _tableControllersPair.right.view;
	UIViewAnimationOptions options = _isRightActive ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft;
	options |= UIViewAnimationOptionShowHideTransitionViews;
	[UIView transitionFromView:from toView:to duration:0.5 options:options completion:^(BOOL finished) {
		self->_isRightActive = !self->_isRightActive;
	}];
}

- (IBAction)findPressed:(id)sender
{
	if(!_findFieldActive && sender)
	{
		_findTextFieldTrailingConstraint.constant = 32;
		_textFieldContainerConstraint.constant = 200;
		if(_findContainerTrailingForPlusInLandscapeConstraint) {
			_findContainerTrailingForPlusInLandscapeConstraint.active = NO;
		}
		_findTextField.enabled = YES;
		[_findTextField becomeFirstResponder];
		_findFieldActive = YES;
	}
	else
	{
		_findFieldActive = NO;
		_textFieldContainerConstraint.constant = 32;
		_findTextFieldTrailingConstraint.constant = 16;
		if(_findContainerTrailingForPlusInLandscapeConstraint) {
			NSInteger horizontalClass = self.traitCollection.horizontalSizeClass;
			if (horizontalClass == UIUserInterfaceSizeClassRegular) {
				_findContainerTrailingForPlusInLandscapeConstraint.active = YES;
			}
		}

		[_findTextField resignFirstResponder];
		_findTextField.enabled = NO;
	}
	
	[UIView animateWithDuration:0.5 animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void) locationItemPressed:(id) sender {
	[self.view.window.rootViewController dismissViewControllerAnimated:YES completion:^{
		[self->_locationPopoverController locationItem].alpha = 0;
		[self->_locationPopoverController localeItem].alpha = 0;
	}];
}

- (void) localeItemPressed:(id) sender {
	[self.view.window.rootViewController dismissViewControllerAnimated:YES completion:^{
		[self->_locationPopoverController locationItem].alpha = 0;
		[self->_locationPopoverController localeItem].alpha = 0;
	}];
}

- (IBAction)locationPressed:(UIButton*)sender {
	if (_findFieldActive) {
		[self findPressed:nil];
	}
	if (!_locationPopoverController) {
		__weak ListsNewsContainerViewController *weakController = self;
		_locationPopoverController = [SomePromiseObject createObjectBasedOn:[UIViewController class]
												protocols:@[@protocol(PopoverItemsProvider)]
										   bindLifetimeTo:nil
											   definition:^(SomePromiseObject* creator) {

												__block UIButton *locationItemBtn = nil;
												__block UIButton *localeItemBtn = nil;
												
												[creator create:@selector(locationItem) with:^UIButton*(UIViewController *self) {
													return locationItemBtn;
												}];

												[creator create:@selector(localeItem) with:^UIButton*(UIViewController *self) {
													return localeItemBtn;
												}];

												[creator override:@selector(viewDidAppear:) with:^void(UIViewController *self, BOOL animated) {
													IMP superImp = sp_superIMP(self, @selector(viewDidAppear:));
													void(* foo)(id, SEL, BOOL) = (void (*)(__strong id, SEL, BOOL))superImp;
													foo(self, @selector(viewDidAppear:), animated);
													
													[locationItemBtn sizeToFit];
													[localeItemBtn sizeToFit];
													[UIView animateWithDuration:0.5 animations:^{
														localeItemBtn.alpha = 1;
														locationItemBtn.alpha = 1;
													}];
												}];

											    [creator override:@selector(viewDidLoad) with:^void(UIViewController *self) {
													sp_voidCallSuper(self, @selector(viewDidLoad));
													
													UIButton* (^buttonCreator)(NSString *text, NSString *image, SEL selector) = ^UIButton*(NSString *text, NSString *image, SEL selector){
														ActionButton *button = [ActionButton buttonWithType:UIButtonTypeCustom];
														[button initializeExplicitly];
														button.clipsToBounds = YES;
														self.view.clipsToBounds = NO;
														[button setTitle:text forState:UIControlStateNormal];
														UIImage *img = [UIImage imageNamed:image];
														[button setImage:img forState:UIControlStateNormal];
														[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
														[self.view addSubview:button];
														button.translatesAutoresizingMaskIntoConstraints = NO;
														[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-3-[button]-3-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(button)]];

														[button addTarget:weakController action:selector forControlEvents:UIControlEventTouchUpInside];
														[button sizeToFit];
														return button;
													};
													UIButton *buttonLocation = buttonCreator(@"Current Location", @"locationItem", @selector(locationItemPressed:));
													UIButton *buttonLocale = buttonCreator(@"Current Locale", @"localeItem", @selector(localeItemPressed:));
													UIView *separator = [[UIView alloc] init];
													separator.backgroundColor = [UIColor lightGrayColor];
													separator.translatesAutoresizingMaskIntoConstraints = NO;
													[self.view addSubview:separator];
													
													[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[buttonLocation]-8-[separator(1)]-8-[buttonLocale(buttonLocation)]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(buttonLocation, buttonLocale, separator)]];
													
													[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-3-[separator]-3-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(separator)]];
													locationItemBtn = buttonLocation;
													localeItemBtn = buttonLocale;
													localeItemBtn.alpha = 0;
													locationItemBtn.alpha = 0;
												}];
		}];
		_locationPopoverController.preferredContentSize = CGSizeMake(200, 100);
		_locationPopoverController.modalPresentationStyle = UIModalPresentationPopover;
	}
	_locationPopoverController.popoverPresentationController.sourceView = sender;
	_locationPopoverController.popoverPresentationController.sourceRect = sender.bounds;
	_locationPopoverController.popoverPresentationController.delegate = self;
	[self.view.window.rootViewController presentViewController:_locationPopoverController animated:YES completion:nil];
}

- (IBAction)menuPressed:(id)sender
{
	if(_menuPresenter.menuShown)
	{
		[_menuPresenter hideMenu];
	}
	else
	{
		[_menuPresenter showMenu];
	}
}

- (IBAction)sizeChangerPressed:(UIButton*)sender
{
	SomePromiseSignal *signalsizeChangerPressed = [[SomePromiseSignal alloc] initWithName:sizeChangingAsked tag:0 message:@{@"button" : sender, @"sender" : @"leftController"} anythingElse:nil];
	NSMutableSet *receivers = [NSMutableSet new];
	[self getAllReceiversForController:self set:receivers];
	[receivers removeObject:self];
	[self sendSignal:signalsizeChangerPressed toObject:receivers.allObjects];
}

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{	
	if([signal.name isEqualToString:readyToGetNewPage])
	{
		return YES;
	}
	
	if([signal.name isEqualToString:mainScreenChangedSignal])
	{
		return YES;
	}
	
	return NO;
}

 - (void)handleTheSignal:(SomePromiseSignal*)signal
 {
	if([signal.name isEqualToString:readyToGetNewPage])
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(self->_moreButton.isEnabled)
			{
				[self->_moreButton sendActionsForControlEvents:UIControlEventTouchUpInside];
			}
		});
	}
	
	if([signal.name isEqualToString:mainScreenChangedSignal])
	{
		NSString *state = signal.message[@"state"];
		if([state isEqualToString:@"Both"])
		{
			[_extendButton setImage:[UIImage imageNamed:@"extend"] forState:UIControlStateNormal];
		}
		else if([state isEqualToString:@"Left"])
		{
			[_extendButton setImage:[UIImage imageNamed:@"minimize"] forState:UIControlStateNormal];
		}
	}
 }

- (IBAction)optionsPressed:(id)sender
{
	SomePromiseSignal *signalOptionsPressed = [[SomePromiseSignal alloc] initWithName:optionsPressed tag:0 message:nil anythingElse:nil];
	NSMutableSet *receivers = [NSMutableSet new];
	[self getAllReceiversForController:self set:receivers];
	[receivers removeObject:self];
	[self sendSignal:signalOptionsPressed toObject:receivers.allObjects];
}

- (IBAction)morePressed:(id)sender
{
	[((AppDelegate*)([UIApplication sharedApplication].delegate)) startAddingPage];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self findPressed:nil];
	return YES;
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	NSInteger horizontalClass = self.traitCollection.horizontalSizeClass;
	if (horizontalClass == UIUserInterfaceSizeClassRegular && _findFieldActive) {
		_findContainerTrailingForPlusInLandscapeConstraint.active = NO;
	}
}

@end

@implementation ListsNewsContainerViewController (PopoverPresentationDelegate)

// Returning UIModalPresentationNone will indicate that an adaptation should not happen.
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
	return UIModalPresentationNone;
}

@end

