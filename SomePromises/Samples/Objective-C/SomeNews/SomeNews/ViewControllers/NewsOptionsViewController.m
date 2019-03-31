//
//  NewsOptionsViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 06/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NewsOptionsViewController.h"
#import "NewsOptionsMainView.h"
#import "SomeNews-Swift.h"

@interface NewsOptionsViewController ()
{
	__weak IBOutlet UIButton *_countryButton;
	__weak IBOutlet UIButton *_languageButton;
	__weak IBOutlet UIButton *_categoryButton;
	__weak IBOutlet UIButton *_sourceButton;
	__weak IBOutlet UISwitch *_useSourceSwitch;
	__weak IBOutlet UISegmentedControl *_modeSegmentControl;
	__weak IBOutlet UIButton *_aboutButton;
}

@property (nonatomic, weak) UISwitch *useSourceSwitch;

@end

@implementation NewsOptionsViewController
@synthesize useSourceSwitch = _useSourceSwitch;

- (void)viewDidLoad
{
    [super viewDidLoad];

	@sp_uibind(_categoryButton, enabled) = @sp_observeSwitch(_useSourceSwitch).map(^(NSNumber *result){
		return @(![result boolValue]);
	});
	
	@sp_uibind(_sourceButton, enabled) = @sp_observeSwitch(_useSourceSwitch);
	
	@sp_startUI(sp_action(_useSourceSwitch, ^(NSNumber *sourceBool) {
		if (![sourceBool boolValue]) {
			[Services.user setSource:nil  withName:nil];
		} else {
			[Services.user restoreSourceIfPossible];
		}
	})) = @sp_observeSwitch(_useSourceSwitch);
}

- (IBAction)buttonPressed:(id)sender
{
	[_useSourceSwitch setOn:([Services.user getSource] ? YES : NO)];
	[((NewsOptionsMainView*)self.view) changeInternalState];
	if (![((NewsOptionsMainView*)self.view) isOpened]) {
		[((AppDelegate*)([UIApplication sharedApplication].delegate)) startUpdate];
	}
	
}

- (IBAction)aboutButtonPressed:(id)sender {
	AboutViewController *aboutVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"AboutViewControllerId"];
	aboutVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	[self presentViewController:aboutVC animated:YES completion:nil];
}

@end
