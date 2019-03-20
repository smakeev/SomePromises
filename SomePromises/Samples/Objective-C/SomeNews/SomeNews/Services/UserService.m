//
//  UserService.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "UserService.h"
#import "ServicesProvider.h"

#define LANGUAGEKEY @"Language"
#define COUNTRYKEY @"Country"
#define CATEGORYKEY @"Category"

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

	NSString *where = _country ? : _language ? : @"Any";
	NSString *category = _category ? : @"Any";

	_state.value = [NSString stringWithFormat:@"Where:%@  Cat:%@  What:%@", where, category, _querry ? : @""];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_country forKey:COUNTRYKEY];
	[defaults setObject:_language forKey:LANGUAGEKEY];
	[defaults setObject:category forKey:CATEGORYKEY];
	[defaults synchronize];
}

- (void) restoreFromDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *language = [defaults objectForKey:LANGUAGEKEY];
	NSString *country = [defaults objectForKey:COUNTRYKEY];
	NSString *category = [defaults objectForKey:CATEGORYKEY];
	if (language) {
	   [self setLanguage:language];
	} else {
		[self setCountry:country];
		[self setCategory:category];
	}
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
	if([category isEqualToString:@"all"] || [category isEqualToString:@"Any"])
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
