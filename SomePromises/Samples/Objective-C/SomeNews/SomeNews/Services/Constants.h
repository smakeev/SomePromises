//
//  Constants.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

@protocol ServicesProviderProtocol;
//extends names
#define exIndexPath @"_extendedIndexPath"

//defines for easy access to helpers
#define StarterPromise getStarterPromise()
#define Services getServices()

#define	retainNetworkIndicator try{} @finally{} [NetworkIndicatorService startUsingNetworkIndicator];
#define releseNetworkIndicator try{} @finally{} [NetworkIndicatorService stopUsingNetworkIndicator];

extern const NSTimeInterval minRequestInteval;

//enums
typedef NS_ENUM(NSInteger, ArticlesViewType)
{
	EViewType_TOP = 0,
	EViewType_BYSOURCE = 1,
};

//helpers
SomePromise* getStarterPromise(void);
NSObject<ServicesProviderProtocol>* getServices(void);

//url parameters
extern NSString * const apiKey;
extern NSString * const mainURL;

//promises names
extern NSString * const topNewsPromise;
extern NSString * const imageLoaderPromise;

//events
extern NSString * const stopUpdate;
extern NSString * const modelRecreated;
extern NSString * const modelArticleAdded;
extern NSString * const waitingForPredownloadedPage;
extern NSString * const expectedPredownloadedPageCame;

//signals
extern NSString * const selectArticle;
extern NSString * const unselectArticle;
extern NSString * const readyToGetNewPage;
extern NSString * const optionsPressed;
extern NSString * const sizeChangingAsked;
extern NSString * const mainScreenChangedSignal;
extern NSString * const hideOptions;
extern NSString * const showOptions;

//settings data base
NSArray *getPossibleCategories(void);
NSArray *getPossibleLanguages(void);
NSArray *getPossibleCountries(void);
