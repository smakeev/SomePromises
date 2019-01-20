//
//  NetworkIndicatorService.h
//  SomeNews
//
//  Created by Sergey Makeev on 01/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkIndicatorService : NSObject

+ (void) startUsingNetworkIndicator;
+ (void) stopUsingNetworkIndicator;

@end

NS_ASSUME_NONNULL_END
