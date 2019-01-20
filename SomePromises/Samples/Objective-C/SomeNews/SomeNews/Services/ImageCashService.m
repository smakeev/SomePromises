//
//  ImageCashService.m
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ImageCashService.h"
#import "ServicesProviderProtocol.h"

@interface ImageCashService ()
{
	NSCache *_cache;
}

@end

@implementation ImageCashService

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		@synchronized(self)
		{
			_cache = [[NSCache alloc] init];
		}
	}
	return self;
}


- (void) addImage:(UIImage*) image toUrl:(NSString*) imageUrl
{
	@synchronized(self)
	{
		[_cache setObject:image forKey:imageUrl];
	}
}

- (UIImage*) imageForUrl:(NSString*) imageUrl
{
	@synchronized(self)
	{
		return [_cache objectForKey:imageUrl];
	}
}

- (void) clear
{
	[_cache removeAllObjects];
}

@end
