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

- (NSString*) rightURL:(NSString*) requestURL {
	if (![requestURL hasPrefix:@"http"])
	{
		requestURL = [NSString stringWithFormat:@"%@%@", @"https:", requestURL];
		NSLog(@"Fixed: %@", requestURL);
	}
	
	requestURL = [requestURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	return requestURL;
}

- (void) setImageUrl:(NSString *)imageUrl {
//start download task
	if ([_url isEqualToString:imageUrl])
		return;
	
	if (_imageDownloader) {
		[_imageDownloader cancel];
		_imageDownloader = nil;
		self.image = [UIImage imageNamed:@"Logo"];
		self->_cell.imageDownloadingIndicator.hidden = NO;
		[self->_cell.imageDownloadingIndicator startAnimating];
	}
	SPMaybe *cell = @sp_weak_maybe(_cell);
	_url = [imageUrl copy];
	NSString *requestURL = [_url copy];
	
	requestURL = [self rightURL:requestURL];
	@retainNetworkIndicator
	_imageDownloader = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString: requestURL] completionHandler:^(NSData *data,
							NSURLResponse *response,
							NSError *error) {
		@releseNetworkIndicator
		//check if this is our needed result (not one from previous position or cancel)
		__block BOOL shouldWeProcide = YES;
		@sp_avoidblockretain(self)
		dispatch_sync(dispatch_get_main_queue(), ^{
			@sp_strongify(self)
			if (![[self rightURL:self->_url] isEqualToString:response.URL.absoluteString]) {
				shouldWeProcide = NO;
			}
		});
		@sp_avoidend(self)
		if (!shouldWeProcide) {
			return;
		}
		
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
			if(error != nil) {
				[Services.images addImage:result toUrl:self->_url];
			}
			cell.map(^(NewsListTableViewCell *validCell){
				[validCell.imageDownloadingIndicator stopAnimating];
				validCell.imageDownloadingIndicator.hidden = YES;
			});
		});
		@sp_avoidend(self)
		}];
		[_imageDownloader resume];
		cell.map(^(NewsListTableViewCell *validCell) {
			[validCell.imageDownloadingIndicator startAnimating];
			validCell.imageDownloadingIndicator.hidden = NO;
		});
}

- (void) dealloc
{
	//stop task if not ready
	[_imageDownloader cancel];
}

@end
