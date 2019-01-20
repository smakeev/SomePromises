//
//  UIImageViewWithDownloader.m
//  SomeNews
//
//  Created by Sergey Makeev on 13/01/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "UIImageViewWithDownloader.h"
#import "NewsListTableViewCell.h"

@interface UIImageViewWithDownloader ()
{
	__weak NewsListTableViewCell* _cell;
	NSURLSessionDataTask *_imageDownloader;
	NSString *_url;
}
@end

@implementation UIImageViewWithDownloader
@synthesize owner = _cell;
- (void) setImageUrl:(NSString *)imageUrl {
//start download task
	if ([_url isEqualToString:imageUrl])
		return;
	[_cell.imageDownloadingIndicator startAnimating];
	_cell.imageDownloadingIndicator.hidden = NO;
_cell.backgroundColor = UIColor.grayColor;
	if (_imageDownloader) {
		[_imageDownloader cancel];
		_imageDownloader = nil;
		self.image = [UIImage imageNamed:@"Logo"];
		self->_cell.imageDownloadingIndicator.hidden = NO;
		[self->_cell.imageDownloadingIndicator startAnimating];
	}
	
	_url = [imageUrl copy];
	NSString *requestURL = [_url copy];
	if (![requestURL hasPrefix:@"http"])
	{
		requestURL = [NSString stringWithFormat:@"%@%@", @"https:", requestURL];
		NSLog(@"Fixed: %@", requestURL);
	}
	
	requestURL = [requestURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
	if(!request || !request.URL)
	{
		UIImage *errorImage = [UIImage imageNamed:@"DownloadError"];
		errorImage.spExtend(@"_errorText",  @"Download error.", nil, nil);
		[Services.images addImage:errorImage toUrl:request.URL.absoluteString];
		self.image = errorImage;
		[self->_cell.imageDownloadingIndicator stopAnimating];
		self->_cell.imageDownloadingIndicator.hidden = YES;
		return;
	}
	_imageDownloader = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,
																								NSURLResponse *response,
																								NSError *error){
		UIImage *result = [UIImage imageWithData:data];
		if(error != nil || result == nil) {
			UIImage *errorImage = [UIImage imageNamed:@"DownloadError"];
			errorImage.spExtend(@"_errorText",  @"Download error.", nil, nil);
			result = errorImage;
		}
		@sp_avoidblockretain(self)
		dispatch_async(dispatch_get_main_queue(), ^{
			@sp_strongify(self)
			self.image = result;
			[Services.images addImage:result toUrl:self->_url];

			[self->_cell.imageDownloadingIndicator stopAnimating];
			self->_cell.imageDownloadingIndicator.hidden = YES;
		});
		@sp_avoidend(self)
																							}];
}

- (void) dealloc
{
	//stop task if not ready
	[_imageDownloader cancel];
}

@end
