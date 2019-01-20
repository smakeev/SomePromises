//
//  ActionButton.m
//  SomeNews
//
//  Created by Sergey Makeev on 01/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ActionButton.h"
#import "PulsingLayer.h"

@interface ButtonPulsingLayerHelper : NSObject <PulsingLayerAnimationDelegate>

@property (nonatomic, weak) ActionButton *owner;

- (instancetype) initWithButton:(ActionButton*)button;
- (void) addPulsingAnimation;

@end

@interface ActionButton ()
{
	CGAffineTransform _initialTransform;
	ButtonPulsingLayerHelper *_pulsingHelper;
}
@end

@implementation ActionButton

- (void) awakeFromNib
{
	[super awakeFromNib];
	_initialTransform = CGAffineTransformIdentity;
	_pulsingHelper = [[ButtonPulsingLayerHelper alloc] initWithButton:self];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self.layer removeAllAnimations];
	
	for(CALayer *layer in self.layer.sublayers)
	{
		[layer  removeAllAnimations];
	}
	self.transform = CGAffineTransformScale(self.transform, 1.4, 1.4);
	[_pulsingHelper addPulsingAnimation];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[UIView animateWithDuration:0.5
						  delay:0
		 usingSpringWithDamping:0.5
		  initialSpringVelocity:6.0
						options:UIViewAnimationOptionAllowUserInteraction
					 animations:^
	 {
		 self.transform = CGAffineTransformIdentity;
	 }
					 completion:^(BOOL finished){
						 if(finished && self.onCompetionAnimations)
						 {
							 [UIView animateWithDuration:0.5 animations:^{
								 self.onCompetionAnimations();
							 }];
						 }
					 }];
	
	[_pulsingHelper addPulsingAnimation];
	[super touchesEnded:touches withEvent:event];
}


@end

@implementation ButtonPulsingLayerHelper

- (instancetype) initWithButton:(ActionButton*)button
{
	self = [super init];
	if(self)
	{
		self.owner = button;
	}
	
	return self;
}

- (UIColor*) colorForLayer
{
	return [UIColor colorNamed:@"PulsingLayerColor"];
}

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	CALayer *layer = (CALayer*)[anim valueForKey:kAnimationRemoveLayer];
	if(layer != nil)
	{
		[layer removeAllAnimations];
		[layer removeFromSuperlayer];
	}
}

- (CGPoint) position
{
	CGPoint point = CGPointZero;
	point.x = self.owner.bounds.size.width / 2;
	point.y = self.owner.bounds.size.height / 2;
	
	return point;
}

- (void) addPulsingAnimation
{
	PulsingLayer *layer = [[PulsingLayer alloc] initWithDelegate:self initilSCale:0 delay:0 duration:1.5 radius:self.owner.frame.size.width];
	[self.owner.layer insertSublayer:layer below:self.owner.layer];
}

@end
