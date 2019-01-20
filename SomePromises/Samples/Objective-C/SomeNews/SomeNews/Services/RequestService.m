//
//  RequestService.m
//  SomeNews
//
//  Created by Sergey Makeev on 04/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "RequestService.h"

@implementation RequestPresenter
@end


@implementation RequestService

- (BOOL) isSameAsUser
{
	if(!self.current)
		return NO;
	NSString *country = [Services.user getCountry];
	if(country == nil && self.current.country != nil)
		return NO;
	if(country != nil && self.current.country == nil)
		return NO;
	if(country && ![country isEqualToString:self.current.country])
		return NO;
	
	NSString *language = [Services.user getLanguage];
	if(language == nil && self.current.language != nil)
		return NO;
	if(language != nil && self.current.language == nil)
		return NO;
	if(language && ![language isEqualToString:self.current.language])
		return NO;
	
	NSString *category = [Services.user getCategory];
	if(category == nil && self.current.category != nil)
		return NO;
	if(category != nil && self.current.category == nil)
		return NO;
	if(category && ![category isEqualToString:self.current.category])
		return NO;
	
	NSString *query = [Services.user getQuery];
	if(query == nil && self.current.querry != nil)
		return NO;
	if(query != nil && self.current.querry == nil)
		return NO;
	if(query && ![query isEqualToString:self.current.querry])
		return NO;
	return YES;
}

@end
