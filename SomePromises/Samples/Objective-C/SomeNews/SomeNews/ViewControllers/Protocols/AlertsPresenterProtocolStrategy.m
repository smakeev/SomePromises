//
//  AlertsPresenterProtocolStrategy.m
//  SomeNews
//
//  Created by Sergey Makeev on 14/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "AlertsPresenterProtocolStrategy.h"
#import  "ContainerableProtocol.h"
@implementation AlertsPresenterProtocolStrategy

- (UIView*) baseAlertView
{
	return nil;
}

- (UIView*) whereToPresent
{
	if ([self conformsToProtocol:@protocol(Containerable)])
	{
		return [((id<Containerable>)(self)) whereToPresentContainerable];
	}
	return self.view;
}

- (void) showBaseAlertWithData:(NSDictionary*)data
{
	//@TODO:
}

- (void) showAlertViewWithContentView:(UIView*(^ _Nullable)(CGSize desiredSize)) contentCreatorBlock
{
	UIView *target = self.whereToPresent;

	UIView *alertBackground = [[UIView alloc] initWithFrame:CGRectZero];
	[target addSubview:alertBackground];
	alertBackground.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
	
	alertBackground.translatesAutoresizingMaskIntoConstraints = NO;

	[alertBackground.centerXAnchor constraintEqualToAnchor:target.centerXAnchor].active = YES;
	[alertBackground.centerYAnchor constraintEqualToAnchor:target.centerYAnchor].active = YES;
	[alertBackground.heightAnchor constraintEqualToAnchor:target.heightAnchor].active = YES;
	[alertBackground.widthAnchor constraintEqualToAnchor:target.widthAnchor].active = YES;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideAlertView:)];
	[alertBackground addGestureRecognizer:tap];
	
	if(contentCreatorBlock)
	{
		UIView *alertView = contentCreatorBlock(target.frame.size);
		alertView.translatesAutoresizingMaskIntoConstraints = NO;
		[alertBackground addSubview:alertView];
		alertBackground.alpha = 0;
		CGRect frame = alertView.frame;
		if(frame.size.width == 0 || frame.size.width > target.frame.size.width)
		{
			frame.size.width = target.frame.size.width;
		}
		if(frame.size.height == 0 || frame.size.height > target.frame.size.height)
		{
			frame.size.height = target.frame.size.height;
		}
		alertView.frame = frame;
		
		//adding constraints.
		[alertView.centerXAnchor constraintEqualToAnchor:target.centerXAnchor].active = YES;
		[alertView.centerYAnchor constraintEqualToAnchor:target.centerYAnchor].active = YES;
		
		CGFloat widthMultiplier = alertView.frame.size.width / target.frame.size.width ;
		CGFloat hightMultiplier = alertView.frame.size.height / target.frame.size.height;
		
		[alertView.widthAnchor constraintEqualToAnchor:target.widthAnchor multiplier:widthMultiplier].active = YES;
		[alertView.heightAnchor constraintEqualToAnchor:target.heightAnchor multiplier:hightMultiplier].active = YES;
		
		//appering
		[UIView animateWithDuration:0.5 animations:^{
			alertBackground.alpha = 1;
		}];
	}
}

- (void) hideAlertView:(UITapGestureRecognizer*)sender;
{
	UIView *alertView = sender.view;
	[UIView animateWithDuration:0.5 animations:^{
		alertView.alpha = 0;
	} completion:^(BOOL finished) {
		[alertView removeFromSuperview];
	}];
}

@end
