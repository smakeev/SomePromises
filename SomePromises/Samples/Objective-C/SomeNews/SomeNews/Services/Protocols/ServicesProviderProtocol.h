//
//  ServicesProviderProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef ServicesProviderProtocol_h
#define ServicesProviderProtocol_h

#import "NetServiceProviderProtocol.h"
#import "UserServiceProviderProtocol.h"

@protocol NetServiceProviderProtocol;
@protocol UserServiceProviderProtocol;
@protocol ImageCashServiceProviderProtocol;

@protocol ServicesProviderProtocol <NSObject>

@property (nonatomic, readonly) NSObject<NetServiceProviderProtocol> *net;
@property (nonatomic, readonly) NSObject<UserServiceProviderProtocol> *user;
@property (nonatomic, readonly) NSObject<ImageCashServiceProviderProtocol> *images;

+ (instancetype) instance;

@end

#endif /* ServicesProviderProtocol_h */
