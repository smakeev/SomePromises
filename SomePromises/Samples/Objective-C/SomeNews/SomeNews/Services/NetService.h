//
//  NetService.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetServiceProviderProtocol.h"

@protocol ServicesProviderProtocol;
@protocol NetServiceProviderProtocol;
@protocol ImageCashServiceProviderProtocol;
@interface NetService : NSObject <NetServiceProviderProtocol>

@property (nonatomic, weak) id<ServicesProviderProtocol> owner;

@end
