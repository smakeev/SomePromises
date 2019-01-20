//
//  DownloadingTableViewCell.h
//  SomeNews
//
//  Created by Sergey Makeev on 01/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityControll;

@end

NS_ASSUME_NONNULL_END
