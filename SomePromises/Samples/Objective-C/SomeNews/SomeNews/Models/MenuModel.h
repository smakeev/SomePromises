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
	ESearchOnStartType_Location = 0,
	ESearchOnStartType_Last     = 1,
	ESearchOnStartType_Nothing  = 2,
};

typedef NS_ENUM(NSInteger, ActionOnClick) {
	EActionOnClick_Open    = 0,
	EActionOnClick_Safari  = 1,
	EActionOnClick_Extend  = 2,
	EActionOnClick_Nothing = 3,
};

@interface MenuModel : NSObject

@property (nonatomic)SearchOnStartType startSearch;
@property (nonatomic)ActionOnClick onCellClicked;
@property (nonatomic)BOOL autoHideSettings;


- (NSString*) getOnLAunchText:(SearchOnStartType) searchType;
- (NSString*) getOnCellClickedText:(ActionOnClick) actionType;

@end

NS_ASSUME_NONNULL_END
