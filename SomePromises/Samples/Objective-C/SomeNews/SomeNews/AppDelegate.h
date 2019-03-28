//
//  AppDelegate.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@protocol ServicesProviderProtocol;
@class ArticlesModel;
@class MenuModel;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (readonly, nonatomic) NSObject<ServicesProviderProtocol> *services;
@property (readonly, nonatomic) ArticlesModel *model;
@property (readonly, nonatomic) MenuModel *modelMenu;

- (void) saveContext;
- (void) startUpdate;
- (void) startAddingPage;
- (void) detectCountry;

@end

