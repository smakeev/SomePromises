//
//  SourcesViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 19/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SourcesViewController.h"
#import "SettingBaseViewController.h"

#define kID          @"id"
#define kCategory    @"category"
#define kCountry     @"country"
#define kDescription @"description"
#define kLanguage    @"language"
#define kName        @"name"
#define kUrl         @"url"

@interface SourcesViewController ()
{
	NSMutableArray *_availableSources;
	SomePromise *_getSourcesPromise;
	NSString *_selected;
	NSString *_selectedName;
	__weak SettingBaseViewController *base;
	BOOL _ready;
}
@end

@implementation SourcesViewController

- (void) handleSources:(NSArray*)sources
{
	[_availableSources addObjectsFromArray: sources];
	NSLog(@"result: %@", _availableSources);
	dispatch_sync(dispatch_get_main_queue(), ^{
		
		self->_ready = YES;
		[self->base.pickerView reloadAllComponents];
		NSString *sourceString = [Services.user getSource];
		NSInteger currentRow = 0;
		BOOL isFound = NO;
		if(sourceString)
		{
			for(NSDictionary *source in self->_availableSources)
			{
				if([source[kID] isEqualToString:sourceString])
				{
					isFound = YES;
					break;
				}
				currentRow++;
			}
		}
		if (!isFound) {
			currentRow = 0;
		}
		[self->base.pickerView selectRow:currentRow inComponent:0 animated:NO];
		self->_selected = self->_availableSources[currentRow][kID];
		self->_selectedName = self->_availableSources[currentRow][kName];
	});
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_getSourcesPromise reject];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	_availableSources = [NSMutableArray new];
	[_availableSources addObject:@{
									kID         : @"N/A",
									kCategory   : @"N/A",
									kCountry    : @"N/A",
									kDescription: @"Don't use particular source",
									kLanguage   : @"N/A",
									kName       : @"All",
									kUrl        : @"N/A",
									}];
	NSObject<NetServiceProviderProtocol> *serviceNet = Services.net;
	_getSourcesPromise = [serviceNet getSources].onSuccess(^(id result) {
		[self handleSources:result[@"sources"]];
	}).onReject(^(NSError *error){
		//@TODO:
	});
	
	for(UIViewController *controller in self.childViewControllers)
	{
			if([controller isKindOfClass:[SettingBaseViewController class]])
			{
				base = (SettingBaseViewController*)controller;
				base.pickerView.delegate = self;
				base.pickerView.dataSource = self;
				[base.pickerView.widthAnchor	constraintEqualToAnchor:base.pickerView.superview.heightAnchor multiplier:.5].active = YES;
				[base.pickerView.heightAnchor	constraintEqualToAnchor:base.pickerView.superview.widthAnchor multiplier:1.0].active = YES;

				base.pickerView.transform = CGAffineTransformMakeRotation(-90 * M_PI / 180);
				_selected = _availableSources[0][kID];
				@sp_avoidblockretain(self)
				@sp_startUI(sp_action(self, ^(UIButton *button){
					@sp_strongify(self)
					guard(self) else {return;}
					[Services.user setSource:self->_selected withName:self->_selectedName];
					[((AppDelegate*)([UIApplication sharedApplication].delegate)) startUpdate];
				})) = @sp_observeControlOnce(base.doneButton, UIControlEventTouchUpInside);
				@sp_avoidend(self)
			}
	}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	_selected     = _availableSources[row][kID];
	_selectedName = _availableSources[row][kName];
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return _availableSources.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view
{
	UIView *viewWithTitle = [[UIView alloc] initWithFrame:CGRectZero];
	
	UIFont * customFont = [UIFont boldSystemFontOfSize:22]; //custom font
	NSString * text = _availableSources[row][kName];
	
	UIView *viewToShow = nil;
	if (!_ready) {
		UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] init];
		[activityView startAnimating];
		viewToShow = activityView;
	} else
	{
		UILabel *fromLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		viewToShow = fromLabel;
		fromLabel.text = text;
		fromLabel.font = customFont;
		fromLabel.numberOfLines = 1;
		fromLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
		fromLabel.adjustsFontSizeToFitWidth = YES;
		fromLabel.minimumScaleFactor = 10.0f/22.0f;
		fromLabel.clipsToBounds = YES;
		fromLabel.backgroundColor = [UIColor clearColor];
		fromLabel.textColor = [UIColor blackColor];
		fromLabel.textAlignment = NSTextAlignmentCenter;
	}
	
	[viewWithTitle addSubview:viewToShow];
	viewToShow.translatesAutoresizingMaskIntoConstraints = NO;
	
	UIView *leftView = [[UIView alloc] initWithFrame:CGRectZero];
	UIView *rightView = [[UIView alloc] initWithFrame:CGRectZero];

	[viewWithTitle addSubview:leftView];
	[viewWithTitle addSubview:rightView];
	leftView.translatesAutoresizingMaskIntoConstraints = NO;
	rightView.translatesAutoresizingMaskIntoConstraints = NO;
	//rightView.backgroundColor = [UIColor redColor];
	
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[viewToShow]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewToShow)]];
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[leftView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(leftView)]];
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[rightView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(rightView)]];
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftView(15)][viewToShow(120)][rightView(15)]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewToShow, leftView, rightView)]];
	
	viewWithTitle.transform = CGAffineTransformMakeRotation(90 * M_PI / 180);
	
	return viewWithTitle;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 150;
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 50;
}
@end
