//
//  NetworkIndicatorService.m
//  SomeNews
//
//  Created by Sergey Makeev on 01/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NetworkIndicatorService.h"
#import "os/lock.h"

static NetworkIndicatorService *__instance = nil;

@interface NetworkIndicatorService ()
{
	os_unfair_lock _lock;
}
@property (nonatomic) NSUInteger networkUsersNow;
@end

@implementation NetworkIndicatorService

- (void) setNetworkUsersNow:(NSUInteger)networkUsersNow
{
	if(networkUsersNow)
		dispatch_async(dispatch_get_main_queue(), ^{
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		});
	else
		dispatch_async(dispatch_get_main_queue(), ^{
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		});
	_networkUsersNow = networkUsersNow;
}

- (void) addUser
{
	os_unfair_lock_lock(&_lock);
	self.networkUsersNow += 1;
	os_unfair_lock_unlock(&_lock);
}

- (void) removeUser
{
	os_unfair_lock_lock(&_lock);
	if(self.networkUsersNow)
		self.networkUsersNow -= 1;
	os_unfair_lock_unlock(&_lock);
}

+ (instancetype) instance
{
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		__instance = [[NetworkIndicatorService alloc] init];
	});
	return __instance;
}

+ (void) startUsingNetworkIndicator
{
	[NetworkIndicatorService.instance addUser];
}

+ (void) stopUsingNetworkIndicator
{
	[NetworkIndicatorService.instance removeUser];
}


@end
