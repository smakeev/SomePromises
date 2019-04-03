//
//  LanguageViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 19/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "LanguageViewController.h"
#import "SettingBaseViewController.h"


@interface LanguageViewController ()
{
	NSArray *_languages;
	NSString *_selected;
}
@end

@implementation LanguageViewController

-(void)viewDidLoad
{
	[super viewDidLoad];
	_languages = getPossibleLanguages();
	for(UIViewController *controller in self.childViewControllers)
	{
			if([controller isKindOfClass:[SettingBaseViewController class]])
			{
				SettingBaseViewController *base = (SettingBaseViewController*)controller;
				base.pickerView.delegate   = self;
				base.pickerView.dataSource = self;
				[base.pickerView.widthAnchor	constraintEqualToAnchor:base.pickerView.superview.heightAnchor multiplier:.5].active = YES;
				[base.pickerView.heightAnchor	constraintEqualToAnchor:base.pickerView.superview.widthAnchor multiplier:1.0].active = YES;

				base.pickerView.transform = CGAffineTransformMakeRotation(-90 * M_PI / 180);
				//set pickerView selectedElement
				NSString *languageString = [Services.user getLanguage];
				NSInteger currentRow = 0;
				if(languageString)
				{
					for(NSDictionary *language in _languages)
					{
						if([language[@"key"] isEqualToString:languageString])
						{
							break;
						}
						currentRow++;
					}
				}
				[base.pickerView selectRow:currentRow inComponent:0 animated:NO];
				_selected = _languages[currentRow][@"key"];
				@sp_avoidblockretain(self)
				@sp_startUI(sp_action(self, ^(UIButton *button){
					@sp_strongify(self)
					guard(self) else {return;}
					[Services.user setLanguage:self->_selected];
					[((AppDelegate*)([UIApplication sharedApplication].delegate)) startUpdate];
				})) = @sp_observeControlOnce(base.doneButton, UIControlEventTouchUpInside);
				@sp_avoidend(self)
				break;
			}
	}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	_selected = _languages[row][@"key"];
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return _languages.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view
{
	UIView *viewWithTitle = [[UIView alloc] initWithFrame:CGRectZero];
	
	UIFont * customFont = [UIFont boldSystemFontOfSize:22]; //custom font
	NSString * text = _languages[row][@"name"];


	UILabel *fromLabel = [[UILabel alloc] initWithFrame:CGRectZero];
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
	[viewWithTitle addSubview:fromLabel];
	fromLabel.translatesAutoresizingMaskIntoConstraints = NO;
	
	UIView *leftView = [[UIView alloc] initWithFrame:CGRectZero];
	UIView *rightView = [[UIView alloc] initWithFrame:CGRectZero];

	[viewWithTitle addSubview:leftView];
	[viewWithTitle addSubview:rightView];
	leftView.translatesAutoresizingMaskIntoConstraints = NO;
	rightView.translatesAutoresizingMaskIntoConstraints = NO;
	//rightView.backgroundColor = [UIColor redColor];
	
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[fromLabel]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fromLabel)]];
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[leftView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(leftView)]];
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[rightView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(rightView)]];
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftView(15)][fromLabel(120)][rightView(15)]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fromLabel, leftView, rightView)]];
	
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
