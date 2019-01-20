//
//  ImageCashService.h
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageCashServiceProviderProtocol.h"
@protocol ServicesProviderProtocol;
@interface ImageCashService : NSObject <ImageCashServiceProviderProtocol>

@property (nonatomic, weak) id<ServicesProviderProtocol> owner;

@end
