//
//  MenuModel.h
//  SomeNews
//
//  Created by Sergey Makeev on 20/03/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SearchOnStartType) {
	ESearchOnStartType_Location,
	ESearchOnStartType_Last,
	ESearchOnStartType_Nothing
};

@interface MenuModel : NSObject

@property (nonatomic)SearchOnStartType startSearch;


@end

NS_ASSUME_NONNULL_END
