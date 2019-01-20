//
//  PulsingLayer.h
//  SomeNews
//
//  Created by Sergey Makeev on 01/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PulsingLayerAnimationDelegate <CAAnimationDelegate>
- (CGPoint) position;
- (UIColor*_Nonnull) colorForLayer;
@end

#define kAnimationRemoveLayer @"animationRemoveLayer"

@interface PulsingLayer : CALayer
{
	CAAnimationGroup *_animationGroup;
	CGFloat _initialPulseScale;
	NSTimeInterval _animationDuration;
	CGFloat _radius;
	double _delay;
}
@property (nonatomic, weak) _Nullable id<PulsingLayerAnimationDelegate> animationDelegate;

- (instancetype _Nullable )initWithDelegate:(_Nullable id<PulsingLayerAnimationDelegate>)delegate initilSCale:(CGFloat)scale delay:(double)delay duration:(NSTimeInterval)duration radius:(CGFloat)radius;
@end

NS_ASSUME_NONNULL_END
