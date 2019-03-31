//
//  RequestService.h
//  SomeNews
//
//  Created by Sergey Makeev on 04/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestPresenter :  NSObject

@property (nonatomic) NSDate *requestSentAt;

@property (nonatomic) NSString *country;
@property (nonatomic) NSString *language;
@property (nonatomic) NSString *category;
@property (nonatomic) NSString *querry;
@property (nonatomic) NSString *source;

@end

@interface RequestService : NSObject

@property (nonatomic) RequestPresenter *current;
- (BOOL) isSameAsUser;

@end

NS_ASSUME_NONNULL_END
