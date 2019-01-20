//
//  MenuContainerView.m
//  SomeNews
//
//  Created by Sergey Makeev on 10/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "MenuContainerView.h"
#import "MenuView.h"


@interface MenuContainerView()
{
	__weak IBOutlet MenuView *_menuView;
}
@property (weak, nonatomic) IBOutlet UIView *touchView;

@end

@implementation MenuContainerView

- (void) awakeFromNib
{
	[super awakeFromNib];
	_menuView.touchView = self.touchView;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	if([_menuView visible])
		return YES;
	
	CGPoint pointInMenu = [self convertPoint:point toView:_menuView];
	if([_menuView pointInside:pointInMenu withEvent:event])
		return YES;
	return NO;
}

@end
