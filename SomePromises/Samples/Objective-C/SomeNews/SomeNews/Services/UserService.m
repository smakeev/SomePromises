//
//  UserService.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "UserService.h"
#import "ServicesProvider.h"

#define LANGUAGEKEY   @"Language"
#define COUNTRYKEY    @"Country"
#define CATEGORYKEY   @"Category"
#define SOURCEKEY     @"Source"
#define SOURCENAMEKEY @"SourceName"

@interface UserService ()
{
	NSString *_querry;
	NSString *_country;
	NSString *_language;
	NSString *_category;
	NSString *_sourceName;
	
	NSString *_lastSource;
	NSString *_lastSourceName;
	
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

	if (_source) {
		_state.value = [NSString stringWithFormat:@"Where:%@, What:%@", _sourceName, _querry ? : @""];
	} else {
		_state.value = [NSString stringWithFormat:@"Where:%@  Cat:%@  What:%@", where, category, _querry ? : @""];
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_country forKey:COUNTRYKEY];
	[defaults setObject:_language forKey:LANGUAGEKEY];
	[defaults setObject:_category forKey:CATEGORYKEY];
	[defaults setObject:_source forKey:SOURCEKEY];
	[defaults setObject:_sourceName forKey:SOURCENAMEKEY];
	[defaults synchronize];
	
	[_delegate onUserHasChangedUserData];
}

- (void) restoreFromDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *language   = [defaults objectForKey:LANGUAGEKEY];
	NSString *country    = [defaults objectForKey:COUNTRYKEY];
	NSString *category   = [defaults objectForKey:CATEGORYKEY];
	NSString *source     = [defaults objectForKey:SOURCEKEY];
	NSString *sourcename = [defaults objectForKey:SOURCENAMEKEY];
	if (language) {
	   [self setLanguage:language];
	} else {
		[self setCountry:country];
		[self setCategory:category];
	}
	if (source) {
		[self setSource:source withName:sourcename];
	}
}

- (NSString*) getCountry
{
	return _country;
}

- (void) setCountry:(NSString *)country
{
	if (_country && [_country isEqualToString:country]) {return;}
	if([country isEqualToString:@"all"])
	{
		_country = nil;
	}
	else
	{
		_language       = nil; //API does not pay attention on langauge if it has country. So just place it to all to reflect in UI.
		_source         = nil;
		_sourceName     = nil;
		_lastSource     = nil;
		_lastSourceName = nil;
		_country        = country;
	}
	[self updateState];
}

- (NSString*) getLanguage
{
	return _language;
}

- (void) setLanguage:(NSString*)language
{
	if (_language && [_language isEqualToString:language]) {return;}
	if([language isEqualToString:@"all"])
	{
		_language = nil;
	}
	else
	{
		_country        = nil; //API does not pay attention on langauge if it has country.
		_category       = nil;
		_source         = nil;
		_sourceName     = nil;
		_lastSource     = nil;
		_lastSourceName = nil;
		_language       = language;
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
	return _source;
}

- (void) setSource:(NSString*)source  withName:(NSString*) name{
	if ([source isEqualToString:@"N/A"] || source == nil) {
		_source     = nil;
		_sourceName = nil;
	} else {
		_source     = [source copy];
		_sourceName = [name copy];
		_lastSource = _source;
		_lastSourceName = _sourceName;
	}
	[self updateState];
}

- (BOOL) restoreSourceIfPossible {
	if (_lastSource) {
		[self setSource:_lastSource withName:_lastSourceName];
		return YES;
	} else {
		return NO;
	}
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
