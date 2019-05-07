//
//  Constants.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "Constants.h"
#import "ServicesProvider.h"

const NSTimeInterval minRequestInteval = 1800;

NSString * const apiKey             = @"c6d8415f12004b5da670e404fe85e7e8"; /* @"8b04ac92772b474e95dafe816feef298";*/
NSString * const mainURL            = @"https://newsapi.org/v2/";
NSString * const topNewsPromise     = @"getNewsPromise";
NSString * const imageLoaderPromise = @"imageLoaderPromise";

//events
NSString * const stopUpdate                    = @"StopUpdate";
NSString * const modelRecreated                = @"ModelRecreatedEvent";
NSString * const modelArticleAdded             = @"ModelArticleAddedEvent";
NSString * const waitingForPredownloadedPage   = @"WaitingForPredownloadedPage";
NSString * const expectedPredownloadedPageCame = @"ExpectedPredownloadedPageCame";

//signals
NSString * const selectArticle           = @"SelectArticleSignal";
NSString * const unselectArticle         = @"UnselectArticleSignal";
NSString * const readyToGetNewPage       = @"ReadyToGetNewPage";
NSString * const optionsPressed          = @"OptionsPressed";
NSString * const sizeChangingAsked       = @"SizeChangingAsked";
NSString * const mainScreenChangedSignal = @"MainScreenChangedSignal";
NSString * const hideOptions             = @"hideOptions";
NSString * const showOptions             = @"showOptions";

//accessors

NSObject<ServicesProviderProtocol>* getServices(void)
{
	return [ServicesProvider instance];
}

SomePromise* getStarterPromise()
{
	return [SomePromise promiseWithName:@"starterPromise" value:@(0) class:nil];
}

NSArray *getPossibleCategories()
{
	return  @[@{@"key" : @"all", @"name" : @"All"}, @{@"key" : @"business", @"name" : @"Business"}, @{@"key" : @"entertainment", @"name" : @"Entertainment"}, @{@"key" : @"general", @"name" : @"General"}, @{@"key" : @"health", @"name" : @"Health"}, @{@"key" : @"science", @"name" : @"Science"}, @{@"key" : @"sports", @"name" : @"Sports"}, @{@"key" : @"technology", @"name" : @"Technology"}];
}

NSArray *getPossibleLanguages(void)
{
	return @[@{@"key" : @"all", @"name" : @"All"}, @{@"key" : @"ar", @"name" : @"Arabic"}, @{@"key" : @"de", @"name" : @"Detch"}, @{@"key" : @"en", @"name" : @"English"}, @{@"key" : @"es", @"name" : @"Espain"}, @{@"key" : @"fr", @"name" : @"French"}, @{@"key" : @"he", @"name" : @"Hebrew"}, @{@"key" : @"it", @"name" : @"Italian"}, @{@"key" : @"nl", @"name" : @"Dutch"}, @{@"key" : @"no", @"name" : @"Norwegian"}, @{@"key" : @"pt", @"name" : @"Portuguese"}, @{@"key" : @"ru", @"name" : @"Russian"}, @{@"key" : @"se", @"name" : @"Swedish"},@{@"key" : @"zh", @"name" : @"Chinese"}];
}

NSArray *getPossibleCountries(void)
{
	return @[@{@"key" : @"all", @"name" : @"All", @"flag" : [UIImage imageNamed:@"un"]},
			@{@"key" : @"ae", @"name" : @"United Arab Emirates", @"flag" : [UIImage imageNamed:@"ae"]},
			@{@"key" : @"ar", @"name" : @"Argentina", @"flag" : [UIImage imageNamed:@"ar"]},
			@{@"key" : @"at", @"name" : @"Austria", @"flag" : [UIImage imageNamed:@"at"]},
			@{@"key" : @"au", @"name" : @"Australia", @"flag" : [UIImage imageNamed:@"au"]},
			@{@"key" : @"be", @"name" : @"Belgium", @"flag" : [UIImage imageNamed:@"be"]},
			@{@"key" : @"bg", @"name" : @"Bulgaria", @"flag" : [UIImage imageNamed:@"bg"]},
			@{@"key" : @"br", @"name" : @"Brazil", @"flag" : [UIImage imageNamed:@"br"]},
			@{@"key" : @"ca", @"name" : @"Canada", @"flag" : [UIImage imageNamed:@"ca"]},
			@{@"key" : @"ch", @"name" : @"Switzerland", @"flag" : [UIImage imageNamed:@"ch"]},
			@{@"key" : @"cn", @"name" : @"China", @"flag" : [UIImage imageNamed:@"cn"]},
			@{@"key" : @"co", @"name" : @"Colombia", @"flag" : [UIImage imageNamed:@"co"]},
			@{@"key" : @"cu", @"name" : @"Cuba", @"flag" : [UIImage imageNamed:@"cu"]},
			@{@"key" : @"cz", @"name" : @"Czech", @"flag" : [UIImage imageNamed:@"cz"]},
			@{@"key" : @"de", @"name" : @"Germany", @"flag" : [UIImage imageNamed:@"de"]},
			@{@"key" : @"eg", @"name" : @"Egypt", @"flag" : [UIImage imageNamed:@"eg"]},
			@{@"key" : @"fr", @"name" : @"France", @"flag" : [UIImage imageNamed:@"fr"]},
			@{@"key" : @"gb", @"name" : @"Great Britain", @"flag" : [UIImage imageNamed:@"gb"]},
			@{@"key" : @"gr", @"name" : @"Greece", @"flag" : [UIImage imageNamed:@"gr"]},
			@{@"key" : @"hk", @"name" : @"Hong Kong", @"flag" : [UIImage imageNamed:@"hk"]},
			@{@"key" : @"hu", @"name" : @"Hungary", @"flag" : [UIImage imageNamed:@"hu"]},
			@{@"key" : @"id", @"name" : @"Indonesia", @"flag" : [UIImage imageNamed:@"id"]},
			@{@"key" : @"ie", @"name" : @"Ireland", @"flag" : [UIImage imageNamed:@"ie"]},
			@{@"key" : @"il", @"name" : @"Israel", @"flag" : [UIImage imageNamed:@"il"]},
			@{@"key" : @"in", @"name" : @"India", @"flag" : [UIImage imageNamed:@"in"]},
			@{@"key" : @"it", @"name" : @"Italy", @"flag" : [UIImage imageNamed:@"it"]},
			@{@"key" : @"jp", @"name" : @"Japan", @"flag" : [UIImage imageNamed:@"jp"]},
			@{@"key" : @"kr", @"name" : @"Korea", @"flag" : [UIImage imageNamed:@"kr"]},
			@{@"key" : @"lt", @"name" : @"Lithuania", @"flag" : [UIImage imageNamed:@"lt"]},
			@{@"key" : @"lv", @"name" : @"Latvia", @"flag" : [UIImage imageNamed:@"lv"]},
			@{@"key" : @"ma", @"name" : @"Morocco", @"flag" : [UIImage imageNamed:@"ma"]},
			@{@"key" : @"mx", @"name" : @"Mexico", @"flag" : [UIImage imageNamed:@"mx"]},
			@{@"key" : @"my", @"name" : @"Malaysia", @"flag" : [UIImage imageNamed:@"my"]},
			@{@"key" : @"ng", @"name" : @"Nigeria", @"flag" : [UIImage imageNamed:@"ng"]},
			@{@"key" : @"nl", @"name" : @"Netherlands", @"flag" : [UIImage imageNamed:@"nl"]},
			@{@"key" : @"no", @"name" : @"Norway", @"flag" : [UIImage imageNamed:@"no"]},
			@{@"key" : @"nz", @"name" : @"New Zealand", @"flag" : [UIImage imageNamed:@"nz"]},
			@{@"key" : @"ph", @"name" : @"Philippines", @"flag" : [UIImage imageNamed:@"ph"]},
			@{@"key" : @"pl", @"name" : @"Poland", @"flag" : [UIImage imageNamed:@"pl"]},
			@{@"key" : @"pt", @"name" : @"Portugal", @"flag" : [UIImage imageNamed:@"pt"]},
			@{@"key" : @"ro", @"name" : @"Romania", @"flag" : [UIImage imageNamed:@"ro"]},
			@{@"key" : @"rs", @"name" : @"Serbia", @"flag" : [UIImage imageNamed:@"rs"]},
			@{@"key" : @"ru", @"name" : @"Russia", @"flag" : [UIImage imageNamed:@"ru"]},
			@{@"key" : @"sa", @"name" : @"Saudi Arabia", @"flag" : [UIImage imageNamed:@"sa"]},
			@{@"key" : @"se", @"name" : @"Sweden", @"flag" : [UIImage imageNamed:@"se"]},
			@{@"key" : @"sg", @"name" : @"Singapore", @"flag" : [UIImage imageNamed:@"sg"]},
			@{@"key" : @"si", @"name" : @"Slovenia", @"flag" : [UIImage imageNamed:@"si"]},
			@{@"key" : @"sk", @"name" : @"Slovakia", @"flag" : [UIImage imageNamed:@"sk"]},
			@{@"key" : @"th", @"name" : @"Thailand", @"flag" : [UIImage imageNamed:@"th"]},
			@{@"key" : @"tr", @"name" : @"Turkey", @"flag" : [UIImage imageNamed:@"tr"]},
			@{@"key" : @"tw", @"name" : @"Taiwan", @"flag" : [UIImage imageNamed:@"tw"]},
			@{@"key" : @"ua", @"name" : @"Ukraine", @"flag" : [UIImage imageNamed:@"ua"]},
			@{@"key" : @"us", @"name" : @"U. S. A.", @"flag" : [UIImage imageNamed:@"us"]},
			@{@"key" : @"ve", @"name" : @"Venezuela", @"flag" : [UIImage imageNamed:@"ve"]},
			@{@"key" : @"za", @"name" : @"South Africa", @"flag" : [UIImage imageNamed:@"za"]},
	];
}

