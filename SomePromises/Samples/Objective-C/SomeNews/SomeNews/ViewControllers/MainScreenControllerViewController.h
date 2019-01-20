//
//  MainScreenControllerViewController.h
//  SomeNews
//
//  Created by Sergey Makeev on 15/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContainerableProtocol.h"

@class ListsNewsContainerViewController;
@class NewsWebPresentationViewController;
@interface MainScreenControllerViewController : UIViewController <Containerable>

@property (nonatomic) ListsNewsContainerViewController *leftController;
@property (nonatomic) NewsWebPresentationViewController *rightController;

@end
