//
//  ServicesProvider.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServicesProviderProtocol.h"
#import "NetServiceProviderProtocol.h"
#import "UserServiceProviderProtocol.h"
#import "ImageCashServiceProviderProtocol.h"

@interface ServicesProvider : NSObject <ServicesProviderProtocol>
- (instancetype) initWithNetService:(NetProvider*)netService userService:(UserProvider*)user imageCash:(ImagesProvider*)images;
@end
