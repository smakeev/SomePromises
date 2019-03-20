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
	
	SomeClassBox<NSString*> *_state;
}

@end


@implementation UserService
@synthesize querry = _querry;
@synthesize source = _source;
@synthesize state = _state;

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		_state = [[SomeClassBox alloc] init];
	}
	return self;
}

- (void) updateState
{
	_state.value = [NSString stringWithFormat:@"Where:%@  Cat:%@  What:%@", _country ? : _language ? : @"Any", _category ? : @"Any", _querry ? : @""];
}

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
		_language = nil; //API does not pay attention on langauge if it has country. So just place it to all to reflect in UI.
		_country = country;
	}
	[self updateState];
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
		_country = nil; //API does not pay attention on langauge if it has country.
		_category = nil;
		_language = language;
	}
	[self updateState];
}

- (NSString*) getCategory
{
	return	_category;// ? : _language ? nil : @"general";
}

- (void) setCategory:(NSString*)category
{
	if([category isEqualToString:@"all"])
	{
		_category = nil;
	}
	else
	{
		_language = nil;
		_category = category;
	}
	[self updateState];
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

- (void) setQuerry:(NSString *)querry
{
	_querry = querry;
	[self updateState];
}

- (NSString*) getMode
{
	return @"Internet"; //@"Archive"
}

@end
