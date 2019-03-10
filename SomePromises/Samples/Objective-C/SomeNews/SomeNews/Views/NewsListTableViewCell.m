//
//  NewsListTableViewCell.m
//  SomeNews
//
//  Created by Sergey Makeev on 13/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NewsListTableViewCell.h"
#import "NetServiceProviderProtocol.h"
#import "UIImageViewWithDownloader.h"

@interface NewsListTableViewCell()

@property (nonatomic, copy) NSString *imageUrl;

@end

@implementation NewsListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
	
	@sp_avoidblockretain(self)
	@sp_startUI(sp_action(self.openInSafari, ^(UIButton *button){
			@sp_strongify(self)
			guard(self) else {return;}
			if(!button.spHas(@"_articleURL"))
			{
				return;
			}
			NSString *url = button.spGet(@"_articleURL");
			[Services.net openInSafariURL:[NSURL URLWithString:url]];
		})) =  @sp_observeControl(self.openInSafari, UIControlEventTouchUpInside);
	@sp_avoidend(self)
	
	@sp_avoidblockretain(self)
	@sp_startUI(sp_action(self.extendCell, ^(UIButton *button){
			@sp_strongify(self)
			guard(self) else {return;}

			[self adjustConstraintsToExtended:self.headerLeadingToImage.active];
		
			[UIView animateWithDuration:0.5 animations:^{
				@sp_strongify(self)
				[self.contentView layoutIfNeeded];
			}];
		})) =  @sp_observeControl(self.extendCell, UIControlEventTouchUpInside);
	@sp_avoidend(self)

	self.image.image = [UIImage imageNamed:@"Logo"];
	self.imageDownloadingIndicator.hidden = NO;
	[self.imageDownloadingIndicator startAnimating];
}

- (void) adjustConstraintsToExtended:(BOOL)extended
{
	if(extended)
	{
		self.headerLeadingToImage.active = NO;
		self.headerLeadingToCellLeft.active = YES;
	}
	else
	{
		self.headerLeadingToCellLeft.active = NO;
		self.headerLeadingToImage.active = YES;
	}
}

- (BOOL) updateImageWithUrl:(NSString*)imageUrl {
	if ([self.imageUrl isEqualToString:imageUrl]) {
		UIImage *image = [Services.images imageForUrl:imageUrl];
		if(image)
		{
			[self.imageDownloadingIndicator stopAnimating];
			self.imageDownloadingIndicator.hidden = YES;
			self.image.image = image;
		}
		return NO;
	}
	self.imageUrl = imageUrl;
	return YES;
}

@end
