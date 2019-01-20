//
//  ListsNewsContainerViewController.h
//  SomeNews
//
//  Created by Sergey Makeev on 15/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContainerableProtocol.h"

@class NewsListViewController;
@class MainScreenControllerViewController;
@interface ListsNewsContainerViewController : UIViewController <Containerable>

@property (weak, nonatomic) UIButton *moreButton;

- (void) addTopController:(NewsListViewController*)controller;
- (void) addSectionsController:(NewsListViewController*)controller;

@end
