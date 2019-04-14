//
//  MenuModel.m
//  SomeNews
//
//  Created by Sergey Makeev on 20/03/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "MenuModel.h"

#define STARTFROMKEY  @"startFrom"
#define ACTIONONCLICK @"actionOnClick"
#define HIDESETTINGS  @"autoHiddingSettings"

@interface MenuModel () {
	NSArray *_onLaunchTexts;
	NSArray *_onCellClickedTexts;
}
@end


@implementation MenuModel
@synthesize startSearch      = _startSearch;
@synthesize onCellClicked    = _onCellClicked;
@synthesize autoHideSettings = _autoHideSettings;

- (instancetype) init {
	self = [super init];
	if (self) {
		_onLaunchTexts = @[@"On application launch start detecting user's locaion to detect current country and search available local news",
								@"On application launch start the last search",
								@"Don't start any search on application start"];


		_onCellClickedTexts = @[@"When click on cell an appropriate news will be shown in App.",
									 @"Open news from cell in Safari",
									 @"Extend or minimize back the cell",
									 @"Don't provide any actions on cell click"];

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		_startSearch      = [defaults integerForKey:  STARTFROMKEY];
		_onCellClicked    = [defaults integerForKey: ACTIONONCLICK];
		_autoHideSettings = [defaults boolForKey   :  HIDESETTINGS];
	}
	return self;
}

- (void) setStartSearch:(SearchOnStartType)startSearch {
		_startSearch = startSearch;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:_startSearch forKey: STARTFROMKEY];
		[defaults synchronize];
}

- (void) setOnCellClicked:(ActionOnClick)onCellClicked {
		_onCellClicked = onCellClicked;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:_onCellClicked forKey: ACTIONONCLICK];
		[defaults synchronize];
}

- (void) setAutoHideSettings:(BOOL)autoHideSettings {
		_autoHideSettings = autoHideSettings;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:_autoHideSettings forKey: HIDESETTINGS];
		[defaults synchronize];
}

- (NSString*) getOnLAunchText:(SearchOnStartType) searchType {

	return _onLaunchTexts[searchType];
}

- (NSString*) getOnCellClickedText:(ActionOnClick) actionType {
	
	return _onCellClickedTexts[actionType];
}


@end
