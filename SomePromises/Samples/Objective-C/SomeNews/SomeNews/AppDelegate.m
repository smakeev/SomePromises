//
//  AppDelegate.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "AppDelegate.h"
#import "NetService.h"
#import "UserService.h"
#import "ServicesProvider.h"
#import "ImageCashService.h"
#import "Constants.h"
#import "ArticlesModel.h"
#import "ArticlesModelView.h"

#import "NewsListViewController.h"
#import "ListsNewsContainerViewController.h"
#import "MainScreenControllerViewController.h"
#import "NewsWebPresentationViewController.h"
#import "MenuModel.h"

#import "RequestService.h"
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate () <UserServiceDelegate>
{
	
	       ServicesProvider   *_services;
	       ArticlesModelView  *_modelView;
	       MenuModel          *_modelMenu;
	__weak SomePromise        *_netWorker;
	
	       RequestService     *_cashedRequestsInfo;
	       CLLocationManager  *_manager;
	       SomePromise        *_locationDetector;
}

@property (atomic) NSMutableArray<SomePromise*> *addingArticlesChain;

@end

@implementation AppDelegate

- (void) startAddingPage
{
	if(_model.pageExpector)
	{
		return;
	}

	SomePromise *currentChain = StarterPromise;
	if(!self.addingArticlesChain)
	{
		self.addingArticlesChain = [NSMutableArray arrayWithArray:@[currentChain]];
	}
	else
	{
		[self.addingArticlesChain addObject:currentChain];
	}
	
	@sp_avoidblockretain(self)
	currentChain.onEachSuccess(^(NSString *name, id result){
		@sp_strongify(self)
		guard(self) else {return;}
		if([name isEqualToString:topNewsPromise])
		{
			[self.model addNextPageWithJSONAndCount:result];
			return;
		}
		else
		{
			@releseNetworkIndicator
			[self.addingArticlesChain removeObject:currentChain];
		}
		
	});
	@sp_avoidend(self)
	
	SPPair *pairWithPage = [_model getNextPage];
	if(pairWithPage == nil)
	{
		SPEventExpector *pageExpector = [SPEventExpector waitForTriggeredEventForTimeInterval:0 accept:^BOOL(NSDictionary *msg) {
			return YES;
		} onReceived:^(NSDictionary *result) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self->_services.net addPage:[self->_model getNextPage] usingChain:currentChain];
			});
		} onTimeout:^{
			//there is no timeout
		} waitOnThread:nil];
		_model.pageExpector = pageExpector;
		pageExpector.onReject = ^{
			self->_model.pageExpector = nil;
		};
	}
	else
	{
		[_services.net addPage:pairWithPage usingChain:currentChain];
	}
}

- (void) startUpdate
{
	if(_cashedRequestsInfo == nil)
	{
		_cashedRequestsInfo = [[RequestService alloc] init];
		_cashedRequestsInfo.current = [[RequestPresenter alloc] init];
		_cashedRequestsInfo.current.requestSentAt = [NSDate date];
		_cashedRequestsInfo.current.language = [Services.user getLanguage];
		_cashedRequestsInfo.current.country = [Services.user getCountry];
		_cashedRequestsInfo.current.category = [Services.user getCategory];
		_cashedRequestsInfo.current.querry = [Services.user getQuery];
	}
	else
	{
		//check if request is not new.
		if([_cashedRequestsInfo isSameAsUser])
		{
			//@TODO: check for time
			NSTimeInterval timePassed = [_cashedRequestsInfo.current.requestSentAt timeIntervalSinceNow];
			NSLog(@"!! Time passed for request: %f", -timePassed);
			if(-timePassed < minRequestInteval)
			{
				[self.model recallSubscribers];
				return;
			}
		}
		else
		{ //keep new request as current
			_cashedRequestsInfo.current = [[RequestPresenter alloc] init];
			_cashedRequestsInfo.current.requestSentAt = [NSDate date];
			_cashedRequestsInfo.current.language = [Services.user getLanguage];
			_cashedRequestsInfo.current.country = [Services.user getCountry];
			_cashedRequestsInfo.current.category = [Services.user getCategory];
			_cashedRequestsInfo.current.querry = [Services.user getQuery];
		}
	}
	[_services.images clear];
	if(_netWorker || self.addingArticlesChain)
	{
		[_netWorker	rejectAllInChain];
		
		for(SomePromise *promise in self.addingArticlesChain)
		{
			[promise rejectAllInChain];
		}
		[self.addingArticlesChain removeAllObjects];
		self.addingArticlesChain = nil;
	}
	
	[self.model reset];
	@sp_avoidblockretain(self)
	_netWorker = [_services.net getTopNews].onEachSuccess(^(NSString *_Nonnull name, id result) {
		@sp_strongify(self);
		guard(self) else {return;}
		if([name isEqualToString:topNewsPromise])
		{
			[self.model recreateWithFirstPageAndTotalElementsCount:result];
			return;
		}
	}).onEachReject(^(NSString *_Nonnull name, NSError *error){
		//@TODO: Handle network errors here
		NSLog(@"!!!! ERROR:%@", error);
	});
	@sp_avoidend(self)
}

- (void) detectCountry {
	_manager = [[CLLocationManager alloc] init];
	_locationDetector = (SomePromise*)
	[SomePromise promiseWithName:@"AskForLocationPromise"
					   resolvers:^(FulfillBlock fulfill, RejectBlock reject, IsRejectedBlock isRejected, ProgressBlock progress) {
						   self->_manager.delegate = [SomePromiseObject createObjectBasedOn:[NSObject class]
																				  protocols:@[@protocol(CLLocationManagerDelegate)]
																			 bindLifetimeTo:self->_manager
																				 definition:^(SomePromiseObject* creator) {
																					 
																					 [creator create:@selector(locationManager:didChangeAuthorizationStatus:) with:^void(NSObject *self, CLLocationManager *locationManager, CLAuthorizationStatus status) {
																						 if (status == kCLAuthorizationStatusRestricted ||
																							 status == kCLAuthorizationStatusDenied) {
																							 reject(nil);
																						 } else if ( status == kCLAuthorizationStatusAuthorizedWhenInUse ||
																									status == kCLAuthorizationStatusAuthorizedAlways) {
																							 [locationManager startUpdatingLocation];
																						 }
																					 }];
																					 
																					 [creator create:@selector(locationManager:didUpdateLocations:) with:^void(NSObject *self, CLLocationManager *locationManager, NSArray<CLLocation *> *locations) {
																						 if(locations == nil || !locations.count || isRejected()) {
																							 return;
																						 }
																						 CLLocation *current = locations[0];;
																						 CLGeocoder *geocoder = [[CLGeocoder alloc] init];
																						 [geocoder reverseGeocodeLocation:current completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
																							 if (placemarks == nil) {
																								 reject(rejectionErrorWithText(@"Geocode error", ESomePromiseError_ConditionReturnsFalse));
																								 return;
																							 }
																							 CLPlacemark *currentLocPlacement = placemarks[0];
																							 NSString *result = currentLocPlacement.ISOcountryCode;
																							 if (result) {
																								 fulfill(result);
																							 } else {
																								 reject(rejectionErrorWithText(@"Geocode error", ESomePromiseError_ConditionReturnsFalse));
																							 }
																						 }];
																					 }];
																				 }];
						   
						   CLAuthorizationStatus status = CLLocationManager.authorizationStatus;
						   switch (status) {
								   
							   case kCLAuthorizationStatusNotDetermined:
								   [self->_manager requestWhenInUseAuthorization];
								   break;
							   case kCLAuthorizationStatusRestricted:
							   case kCLAuthorizationStatusDenied:
								   reject(nil);
								   break;
							   case kCLAuthorizationStatusAuthorizedAlways:
							   case kCLAuthorizationStatusAuthorizedWhenInUse:
								   [self->_manager startUpdatingLocation];
								   break;
						   }
					   } class:[NSString class]].onReject(^(NSError* error) {
						   //show alert
						   guard (!error) else {return;} //if there is error, than error is in geocode or rejected by user action. Don't show the alert though
						   dispatch_async(dispatch_get_main_queue(), ^{
							   UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Location Service Disabled" message:@"Enable Location Services in Settings to allow the app to determine your current location." preferredStyle:UIAlertControllerStyleAlert];
							   UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
							   [controller addAction:action];
							   [self.window.rootViewController presentViewController:controller animated:YES completion:nil];
						   });
					   }).onSuccess(^(NSString *countryCode) {
						   dispatch_async(dispatch_get_main_queue(), ^{
							   [Services.user setCountry:countryCode];
							   [self startUpdate];
						   });
					   }).always(^(id result, NSError *error) {
						   dispatch_async(dispatch_get_main_queue(), ^{
							   [self->_manager stopUpdatingLocation];
						   });
					   });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	//setting up cache level 2 for image downloading
	NSUInteger commonCache2Capcacity = 500 * 1024 * 1024;
	NSURLCache *sharedURLCache = [[NSURLCache alloc] initWithMemoryCapacity:commonCache2Capcacity diskCapacity:commonCache2Capcacity diskPath:@"cacheLevel2"];
	[NSURLCache setSharedURLCache:sharedURLCache];
	
	//services
	_services = [SPFabric new].registerClass([UserService class], ^(SPProducer *producer){
		return [[UserService alloc] init];
	}).registerClass([NetService class], ^(SPProducer *produder){
		return [[NetService alloc] init];
	}).registerClass([ImageCashService class], ^(SPProducer *producer){
		return [[ImageCashService alloc] init];
	}).registerClass([ServicesProvider class], ^(SPProducer *producer){
		NetService *netSetvice = producer.produce([NetService class]);
		UserService *userService = producer.produce([UserService class]);
		ImageCashService *imageCash = producer.produce([ImageCashService class]);
		ServicesProvider *services = [[ServicesProvider instance] initWithNetService:netSetvice userService:userService imageCash:imageCash];
		netSetvice.owner = services;
		userService.owner = services;
		imageCash.owner = services;
		return services;
	}).produce([ServicesProvider class]);
	Services.user.delegate = self;
	
	//setting up the App.

	//Models and viewModels
	_model = [ArticlesModel new];
	_modelView = [[ArticlesModelView alloc] initWithModel:_model];
	_modelMenu = [[MenuModel alloc] init];
	
	//UI
	NewsListViewController *leftController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainNewsListController"];
	leftController.viewType = EViewType_BYSOURCE;
	[leftController setupWithViewModel:_modelView];
	
	NewsListViewController *rightController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainNewsListController"];
	rightController.viewType = EViewType_TOP;
	[rightController setupWithViewModel:_modelView];

	ListsNewsContainerViewController *newsListsContainer = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainListsContainer"];
	[newsListsContainer addTopController:rightController];
	[newsListsContainer addSectionsController:leftController];

	@sp_uibind(newsListsContainer.moreButton, enabled) = @sp_observe(_model, pagesRemain).map(^(NSNumber *pages){
		NSInteger pagesInt = [pages integerValue];
		return @(pagesInt ? YES : NO);
	});

	NewsWebPresentationViewController *webController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NewsWebController"];

	MainScreenControllerViewController *mainController = (MainScreenControllerViewController*)self.window.rootViewController;
	mainController.leftController = newsListsContainer;
	mainController.rightController = webController;
	
	if (_modelMenu.startSearch == ESearchOnStartType_Last) {
		[Services.user restoreFromDefaults];
	} else if (_modelMenu.startSearch == ESearchOnStartType_Location) {
			[self detectCountry];
	}
	[self startUpdate];
	return YES;
}

- (void) onUserHasChangedUserData {
	guard (_locationDetector) else {return;}
	[_locationDetector rejectWithError:rejectionErrorWithText(@"User changed info", ESomePromiseError_ConditionReturnsFalse)];
	_locationDetector = nil;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"SomeNews"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
