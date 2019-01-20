//
//  NewsOptionsMainView.m
//  SomeNews
//
//  Created by Sergey Makeev on 06/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NewsOptionsMainView.h"
#import "ActionButton.h"

#define kSize 480

@interface NewsOptionsMainView ()
{
	BOOL shouldHide;
}
@property (weak, nonatomic) IBOutlet UIView *optionsPresenterView;
@property (weak, nonatomic) IBOutlet ActionButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIView *buttonAboveLayerView;
@property (weak, nonatomic) IBOutlet UIView *controlPressView;

@end

@implementation NewsOptionsMainView

- (void) awakeFromNib
{
	[super awakeFromNib];
	self.optionsPresenterView.layer.cornerRadius = kSize / 2;
	self.optionsPresenterView.layer.masksToBounds = NO;
	self.optionsPresenterView.layer.shouldRasterize = YES;
	self.optionsPresenterView.layer.rasterizationScale = [UIScreen mainScreen].scale;
	self.optionsButton.layer.cornerRadius = 40;
	self.optionsButton.layer.masksToBounds = NO;
	self.optionsButton.layer.shouldRasterize = YES;
	self.optionsButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
	self.optionsButton.layer.borderColor = [UIColor whiteColor].CGColor;
	self.optionsButton.layer.borderWidth = 2.0;
	self.buttonAboveLayerView.layer.cornerRadius = 40;
	self.buttonAboveLayerView.layer.masksToBounds = NO;
	self.buttonAboveLayerView.layer.shouldRasterize = YES;
	self.buttonAboveLayerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
	
	self.controlPressView.layer.cornerRadius = 60;
	self.controlPressView.layer.masksToBounds = NO;
	self.controlPressView.layer.shouldRasterize = YES;
	self.controlPressView.layer.rasterizationScale = [UIScreen mainScreen].scale;
	
	self.optionsPresenterView.transform = CGAffineTransformMakeScale(0, 0);
	shouldHide = NO;
}

- (void) changeInternalState
{
 	[UIView animateWithDuration:0.5 animations:^{
		if(self->shouldHide)
		{
			self.optionsPresenterView.transform = CGAffineTransformMakeScale(0.1, 0.1);
			self->shouldHide = NO;
		}
		else
		{
			self.optionsPresenterView.transform = CGAffineTransformMakeScale(1.0, 1.0);
			self->shouldHide = YES;
		}

		[self layoutIfNeeded];
 	}];
	self.optionsButton.onCompetionAnimations = ^{

		if(self->shouldHide)
		{
			self.optionsButton.transform = CGAffineTransformMakeRotation(45 * M_PI / 180);
		}
		self.buttonAboveLayerView.backgroundColor = self->shouldHide ?
			[UIColor blackColor] : [UIColor whiteColor];
	};
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	CGPoint pointInPresenter = [self convertPoint:point toView:self.optionsPresenterView];
	CGPoint pointInControl = [self convertPoint:point toView:self.controlPressView];

    if([self.optionsPresenterView pointInside:pointInPresenter withEvent:event] ||
    	[self.controlPressView pointInside:pointInControl withEvent:event]){
        return YES;
    }else{
        return NO;
    }
}


@end
