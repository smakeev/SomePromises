//
//  NewsListTableViewCell.h
//  SomeNews
//
//  Created by Sergey Makeev on 13/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageViewWithDownloader.h"

@interface NewsListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageViewWithDownloader *image;
@property (nonatomic, readonly) NSString *imageUrl;
@property (weak, nonatomic) IBOutlet UILabel *header;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UILabel *info;
@property (weak, nonatomic) IBOutlet UIButton *openInSafari;
@property (weak, nonatomic) IBOutlet UIButton *open;
@property (weak, nonatomic) IBOutlet UIButton *extendCell;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *imageDownloadingIndicator;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerLeadingToImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerLeadingToCellLeft;

@property (nonatomic) NSInteger indexOfAarticle;

- (void) adjustConstraintsToExtended:(BOOL)extended;
- (BOOL) updateImageWithUrl:(NSString*)imageUrl;

@end
