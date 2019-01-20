//
//  ServicesProvider.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ServicesProvider.h"
#import "NetService.h"
#import "UserService.h"

@interface ServicesProvider ()
{
	NetProvider *_netService;
	UserProvider *_userService;
	ImagesProvider *_imagesService;
}

@end

static ServicesProvider *__provider;

@implementation ServicesProvider
@synthesize net = _netService;
@synthesize user = _userService;
@synthesize images = _imagesService;

+ (instancetype) instance
{
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		__provider = [ServicesProvider alloc];
	});
	return __provider;
}

- (instancetype) initWithNetService:(NetProvider*)netService userService:(UserProvider*)user imageCash:(ImagesProvider*)images
{
	self = [super init];
	
	if(self)
	{
		_netService = netService;
		_userService = user;
		_imagesService = images;
	}

	return self;
}

@end
