//
//  MenuView.h
//  SomeNews
//
//  Created by Sergey Makeev on 10/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kXMenuScale 0.1

NS_ASSUME_NONNULL_BEGIN

@interface MenuView : UIView

- (BOOL) visible;
- (void) makeVisible:(BOOL) visible;

@property (weak, nonatomic)  UIView *touchView;

@end

NS_ASSUME_NONNULL_END
