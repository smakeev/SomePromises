//
//  MenuView.m
//  SomeNews
//
//  Created by Sergey Makeev on 10/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "MenuView.h"

@interface MenuView ()
{
	BOOL _visible;
	
}

@end

@implementation MenuView

- (void) makeVisible:(BOOL) visible
{
	self.backgroundColor = visible ? [UIColor colorNamed:@"background"] : [UIColor clearColor];
	self.touchView.alpha = visible ? 1 : 0.5;
	_visible = visible;
}

- (BOOL) visible
{
	return _visible;
}

@end
