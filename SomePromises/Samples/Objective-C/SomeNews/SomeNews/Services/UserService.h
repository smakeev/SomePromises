//
//  UserService.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserServiceProviderProtocol.h"

@protocol UserServiceProviderProtocol;
@protocol ServicesProviderProtocol;
@interface UserService : NSObject <UserServiceProviderProtocol>

@property (nonatomic, copy) NSString *querry;

@property (nonatomic, weak) id<ServicesProviderProtocol> owner;


@end
