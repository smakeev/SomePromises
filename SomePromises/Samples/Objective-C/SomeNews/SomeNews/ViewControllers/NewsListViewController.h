//
//  NewsListViewController.h
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContainerableProtocol.h"

@protocol ArticlesModelViewProtocol;
@interface NewsListViewController : UIViewController <Containerable>

@property (nonatomic) ArticlesViewType viewType;

- (void) setupWithViewModel:(id<ArticlesModelViewProtocol>)viewModel;

@end
