//
//  UserService.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "UserService.h"
#import "ServicesProvider.h"

@interface UserService ()
{
	NSString *_querry;
	NSString *_country;
	NSString *_language;
	NSString *_category;
}

@end


@implementation UserService
@synthesize querry = _querry;
@synthesize source = _source;

- (NSString*) getCountry
{
	return _country;
}

- (void) setCountry:(NSString *)country
{
	if([country isEqualToString:@"all"])
	{
		_country = nil;
	}
	else
	{
		_country = country;
	}
}

- (NSString*) getLanguage
{
	return _language;
}

- (void) setLanguage:(NSString*)language
{
	if([language isEqualToString:@"all"])
	{
		_language = nil;
	}
	else
	{
		_language = language;
	}
}

- (NSString*) getCategory
{
	return	_category ? : _language ? nil : @"general";
}

- (void) setCategory:(NSString*)category
{
	if([category isEqualToString:@"all"])
	{
		_category = nil;
	}
	else
	{
		_category = category;
	}
}

- (NSString*) getSource
{
	return nil;
}

- (NSString*) pageSize
{
	return @"100";
}

- (NSString*) getQuery
{
	return _querry;
}

- (NSString*) getMode
{
	return @"Internet"; //@"Archive"
}

@end
