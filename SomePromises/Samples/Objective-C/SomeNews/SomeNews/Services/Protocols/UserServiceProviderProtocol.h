//
//  UserServiceProviderProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef UserServiceProviderProtocol_h
#define UserServiceProviderProtocol_h

@protocol UserServiceDelegate;
@protocol UserServiceProviderProtocol <NSObject>

@property (nonatomic, weak) id<UserServiceDelegate> delegate;
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
- (void) setSource:(NSString*)source withName:(NSString*) name;
- (NSString*) pageSize;
- (NSString*) getQuery;
- (NSString*) getMode;
- (void) restoreSourceIfPossible;

@end
typedef NSObject<UserServiceProviderProtocol> UserProvider;

#endif /* UserServiceProviderProtocol_h */
