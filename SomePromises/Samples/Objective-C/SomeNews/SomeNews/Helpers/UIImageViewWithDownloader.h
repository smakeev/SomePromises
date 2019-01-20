//
//  UIImageViewWithDownloader.h
//  SomeNews
//
//  Created by Sergey Makeev on 13/01/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NewsListTableViewCell;
@interface UIImageViewWithDownloader : UIImageView

@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, weak) NewsListTableViewCell *owner;

@end

NS_ASSUME_NONNULL_END
