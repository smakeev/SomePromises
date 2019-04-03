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
	
	BOOL _useSources;
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
	
	@sp_avoidblockretain(self);
	@sp_startUI(sp_action(_useSourceSwitch, ^(NSNumber *sourceBool) {
		@sp_strongify(self)
		guard(self) else {return;}
		if(self->_useSources == [sourceBool boolValue]) { return; }
		self->_useSources = [sourceBool boolValue];
		if (![sourceBool boolValue]) {
			[Services.user setSource:nil  withName:nil];
		} else {
			if (![Services.user restoreSourceIfPossible]) {
				[self->_sourceButton sendActionsForControlEvents:UIControlEventTouchUpInside];
			}
		}
	})) = @sp_observeSwitch(_useSourceSwitch);
	@sp_avoidend(self)
	
	//on each user change check if there is a source
	@sp_avoidblockretain(self);
	Services.user.state.bind(self, ^(NSString *userState) {
		NSLog(@"!! source now: %@", [Services.user source]);
		@sp_strongify(self)
		guard (self) else {return;}
		if ([Services.user source] == nil &&
			self->_useSourceSwitch.isOn) {
			[self->_useSourceSwitch setOn:NO];
		}
	});
	@sp_avoidend(self)

}

- (IBAction)buttonPressed:(id)sender
{
	_useSources = _useSourceSwitch.isOn;
	_categoryButton.enabled = !_useSourceSwitch.isOn;
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
