//
//  MenuViewController.h
//  SomeNews
//
//  Created by Sergey Makeev on 10/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MenuViewController : UIViewController

@property (nonatomic, readonly) BOOL menuShown;
@property (nonatomic, readonly) NSInteger menuShownPercent;

- (void) showMenu;
- (void) hideMenu;

@end

NS_ASSUME_NONNULL_END
