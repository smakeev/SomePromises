//
//  ShimmerAnimatedLabel.m
//  SomeNews
//
//  Created by Sergey Makeev on 15/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ShimmerAnimatedLabel.h"

@interface ShimmerAnimatedLabel ()
{
	UILabel *_topLabel;
	UILabel *_baseLabel;
	CAGradientLayer *_gradientLayer;
}

@end

@implementation ShimmerAnimatedLabel

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		_baseLabel = [[UILabel alloc] initWithFrame:frame];
		_baseLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_baseLabel];
		
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_baseLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_baseLabel)]];
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-3-[_baseLabel]-3-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_baseLabel)]];
		
		_baseLabel.textColor = [UIColor blueColor];
		_baseLabel.text = self.text;
		
		_topLabel = [[UILabel alloc] initWithFrame:frame];
		_topLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_topLabel];
		
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_topLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_topLabel)]];
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-3-[_topLabel]-3-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_topLabel)]];
		
		_topLabel.textColor = [UIColor whiteColor];
		_topLabel.text = self.text;
		
		_gradientLayer = [[CAGradientLayer alloc] init];
		_gradientLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor];
		_gradientLayer.locations = @[@(0), @(0.5), @(1)];
		_gradientLayer.frame = _topLabel.frame;
		_gradientLayer.transform = CATransform3DMakeRotation(45 * M_PI / 180, 0, 0, 1);
		_topLabel.layer.mask = _gradientLayer;
		
		[self addAnimation];
	}
	return self;
}

- (void) addAnimation
{
	[_gradientLayer removeAllAnimations];

	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
	animation.fromValue = @(-self.frame.size.width);
	animation.toValue = @(self.frame.size.width);
	animation.duration = 15.0;
	animation.repeatCount = HUGE_VALF;
	[_gradientLayer addAnimation:animation forKey:@"animationKey"];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	_gradientLayer.frame = _topLabel.frame;
	[self addAnimation];
}


- (void) setText:(NSString *)text
{
	_topLabel.text = text;
	_baseLabel.text = text;
	_gradientLayer.frame = _topLabel.frame;
	[self addAnimation];
}

@end
