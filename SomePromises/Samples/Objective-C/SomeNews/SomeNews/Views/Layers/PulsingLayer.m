//
//  PulsingLayer.m
//  SomeNews
//
//  Created by Sergey Makeev on 01/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "PulsingLayer.h"

@implementation PulsingLayer


- (void) subinit //initialize with defaults
{
	_animationGroup = [[CAAnimationGroup alloc] init];
	_initialPulseScale = 0.0f;
	_animationDuration = 1.5f;
	_radius = 200;
	_delay = 0.0;
	self.position = [self.animationDelegate position];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self)
	{
		[self subinit];
	}
	return self;
}

- (instancetype)initWithLayer:(id)layer
{
	self = [super initWithLayer:layer];
	if(self)
	{
		[self subinit];
	}
	return self;
}

- (instancetype)initWithDelegate:(id<PulsingLayerAnimationDelegate>)delegate initilSCale:(CGFloat)scale delay:(double)delay duration:(NSTimeInterval)duration radius:(CGFloat)radius
{
	self = [super init];
	if(self)
	{
		_animationDelegate = delegate;
		[self subinit];
		_delay = delay;
		self.backgroundColor = [delegate colorForLayer].CGColor;
		self.contentsScale = [UIScreen mainScreen].scale;
		self.opacity = 0;
		_radius = radius;
		_initialPulseScale = scale;
		_animationDuration = duration;
		self.bounds = CGRectMake(0, 0, _radius * 2, radius * 2);
		self.cornerRadius = _radius;
		self.masksToBounds = NO;
		self.shouldRasterize = YES;
		self.rasterizationScale = [UIScreen mainScreen].scale;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			  [self setupAnimationGroup];
			  dispatch_async(dispatch_get_main_queue(), ^
				{
					[self addAnimation:self->_animationGroup forKey:@"pulse"];
				});
		});

	}
	return self;
}

- (CABasicAnimation*) createScaleAnimation
{
	CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
	
	scaleAnimation.fromValue = @(_initialPulseScale);
	scaleAnimation.toValue = @(1);
	scaleAnimation.duration = _animationDuration;
	
	return scaleAnimation;
}

- (CAKeyframeAnimation*) createOpacityAnimation
{
	CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	opacityAnimation.duration = _animationDuration;
	opacityAnimation.values = @[@0.4, @0.8, @0];
	opacityAnimation.keyTimes = @[@0, @0.2, @1];
	
	return opacityAnimation;
}

- (void) setupAnimationGroup
{
	//_animationGroup = [CAAnimationGroup animation];
	_animationGroup.delegate = _animationDelegate;
	_animationGroup.duration = _animationDuration;
	_animationGroup.timingFunction =  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
	_animationGroup.animations = @[[self createScaleAnimation], [self createOpacityAnimation]];
	[_animationGroup setValue:self forKey:kAnimationRemoveLayer];
	_animationGroup.beginTime = CACurrentMediaTime() + _delay;
}

@end
