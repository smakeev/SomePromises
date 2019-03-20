//
//  UserServiceProviderProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef UserServiceProviderProtocol_h
#define UserServiceProviderProtocol_h

@protocol UserServiceProviderProtocol <NSObject>

@property (nonatomic, readonly, copy)NSString *source;
@property (nonatomic, readonly, copy)NSString *querry;
@property (nonatomic, readonly) SomeClassBox<NSString*> *state;

- (void) restoreFromDefaults;
- (NSString*) getCountry;
- (void) setCountry:(NSString*)country;
- (NSString*) getLanguage;
- (void) setLanguage:(NSString*)language;
- (NSString*) getCategory;
- (void) setCategory:(NSString*)category;
- (NSString*) getSource;
- (NSString*) pageSize;
- (NSString*) getQuery;
- (NSString*) getMode;

@end
typedef NSObject<UserServiceProviderProtocol> UserProvider;

#endif /* UserServiceProviderProtocol_h */
