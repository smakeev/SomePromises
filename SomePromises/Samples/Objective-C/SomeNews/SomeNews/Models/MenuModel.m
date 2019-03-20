//
//  MenuModel.m
//  SomeNews
//
//  Created by Sergey Makeev on 20/03/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "MenuModel.h"

#define STARTFROMKEY @"startFrom"

@implementation MenuModel
@synthesize startSearch = _startSearch;

- (instancetype) init {
	self = [super init];
	if (self) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		_startSearch = [defaults integerForKey:STARTFROMKEY];
	}
	return self;
}

- (void) setStartSearch:(SearchOnStartType)startSearch {
		_startSearch = startSearch;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:_startSearch forKey:STARTFROMKEY];
		[defaults synchronize];
}

@end
