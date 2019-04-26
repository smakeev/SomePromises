//
//  ArticlesModel.m
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "Constants.h"
#import "ArticlesModel.h"
#import "ServicesProviderProtocol.h"
#import "ImageCashServiceProviderProtocol.h"

@interface ArticleItem ()

@property (nonatomic) NSString *sourceId;
@property (nonatomic) NSString *sourceName;
@property (nonatomic) NSString *author;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *articleDescription;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *imageUrl;
@property (nonatomic) NSString *date;
@property (nonatomic) NSString *content;
@property (nonatomic) NSInteger index;

@end

@implementation ArticleItem

+ (instancetype) createWithJSON:(NSDictionary*)JSON index:(NSInteger)index
{

	ArticleItem *item = [[ArticleItem alloc] init];
	[item activeteWithJSON:JSON atIndex:index];
	return item;
}

- (void) activeteWithJSON:(NSDictionary*)JSON atIndex:(NSInteger)index
{
	self.index = index;

	NSDictionary *sourceJSON = JSON[@"source"];
	
	self.sourceId = sourceJSON[@"id"];
	self.sourceName = sourceJSON[@"name"];
	if(![self.sourceId isKindOfClass:[NSString class]])
	{
		self.sourceId = self.sourceName;
	}
	if(![self.sourceId isKindOfClass:[NSString class]])
	{
		self.sourceId = @"Unknown";
		self.sourceName = @"Unknown";
	}
	self.author = JSON[@"author"];
	self.title = JSON[@"title"];
	self.articleDescription = JSON[@"description"];
	self.url = JSON[@"url"];
	self.imageUrl = JSON[@"urlToImage"];
	if([self.imageUrl isKindOfClass:[NSString class]])
	{
		if (![self.imageUrl hasPrefix:@"http"])
		{
			self.imageUrl = [NSString stringWithFormat:@"%@%@", @"https:", self.imageUrl];
		}
		self.imageUrl = [self.imageUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	}
	
	self.date = JSON[@"publishedAt"];
	self.content = JSON[@"content"];
}

@end

@interface ArticlesModel ()
{
	dispatch_queue_t _sync;
	NSInteger _currentPage;
	SomePromise *_moreDownloader;
	SPArray *_pages; //keep JSON pages.
	NSInteger _index;
}

@end

@implementation ArticlesModel

-(void) setPageExpector:(SPEventExpector*)expector
{
	dispatch_sync(_sync, ^{
		self->_pageExpector = expector;
	});
}


+ (instancetype) new
{
	return [[ArticlesModel alloc] init];
}

- (instancetype) init
{
	self = [super init];
	if(self)
	{
		_sync = dispatch_queue_create("model_sync_queue", DISPATCH_QUEUE_SERIAL);
		_articles = [SPArray new];
		_JSONPages = [SPArray new];
	}
	return self;
}

- (void) recallSubscribers
{
	dispatch_sync(_sync, ^{
		[self spTrigger:modelRecreated message:nil];
		//create new first page.
		for (SPArrayElementWrapper *article in self->_articles)
		{
			[self spTrigger:modelArticleAdded message:@{@"article" : article.value}];
		}
	});
}

- (void) reset {
	dispatch_sync(self->_sync, ^{
		self->_index = 0;
		[self->_moreDownloader rejectAllInChain];
		self->_articles = [SPArray new];
		self->_pages = [SPArray new];
		[self spTrigger:modelRecreated message:nil];
	});
}

- (void) recreateWithFirstPageAndTotalElementsCount:(SPPair*)JSONandCount
{
	__block NSArray *pageJSON = nil;
	[self.pageExpector reject];
	dispatch_sync(_sync, ^{
		self->_index = 0;
		[self->_moreDownloader rejectAllInChain];
		self->_articles = [SPArray new];
		self->_pages = [SPArray new];
		[self spTrigger:modelRecreated message:nil];
		NSObject<NetServiceProviderProtocol> *serviceNet = Services.net;
		NSObject<UserServiceProviderProtocol> *serviceUser = Services.user;
		NSInteger pageSize = [[serviceUser pageSize] intValue];
		pageJSON = JSONandCount.right;
		[self->_pages add:pageJSON];
		NSInteger totalResults = [JSONandCount.left integerValue];
		self->_currentPage = 1;
		if(totalResults > pageSize)
		{
			NSInteger result  = totalResults / pageSize;
			self.pagesRemain = totalResults % pageSize ? @(result) : @(result - 1);
		}
		else
		{
			self.pagesRemain = @(0);
		}
		
		//predownloading pages from 2nd. //don't predownload images
		self->_moreDownloader = [serviceNet predownloadPagesJson:[self.pagesRemain integerValue]].onEachSuccess(^(NSString *name, SPPair *result){
			dispatch_sync(self->_sync, ^{
				if([name isEqualToString:@"starterPromise"])
					return;
				NSArray *pageJSON = ((SPPair*)result).right;
				if(((NSNumber*)((SPPair*)result).left).integerValue == 0) {
					self.pagesRemain = @(self.pagesRemain.integerValue - 1);
				}
				[self->_pages add:pageJSON];

				[self.pageExpector trigger:nil];
				if(self.pageExpector)
				{
					self->_pageExpector = nil;
				}
				[self spTrigger:expectedPredownloadedPageCame message:nil];
			});
		}).onEachReject(^(NSString *name, NSError *error){
			dispatch_sync(self->_sync, ^{
				if([name isEqualToString:@"starterPromise"])
					return;
		
				[self.pageExpector trigger:nil];
				if(self.pageExpector)
				{
					self->_pageExpector = nil;
				}
				[self spTrigger:expectedPredownloadedPageCame message:nil];
				self.pagesRemain = @(self.pagesRemain.integerValue - 1);
			});
		});
	});
	
	[self addPageWithJSON:pageJSON];
}

- (void) addPageWithJSON:(NSArray*)JSON
{
	dispatch_sync(_sync, ^{
		for (NSDictionary *articleJSON in JSON)
		{
			ArticleItem *article = [ArticleItem createWithJSON:articleJSON index:self->_index++];
			[self->_articles add:article];
			[self spTrigger:modelArticleAdded message:@{@"article" : article}];
		}
	});
}

- (SPPair*) getNextPage
{
	__block SPPair *result = nil;
	dispatch_sync(_sync, ^{
		guard(self->_pages) else {return;}
		if(self->_currentPage < self->_pages.count)
			result = [SPPair pairWithLeft:@(self->_pages.count) right:self->_pages[self->_currentPage]];
		else
		{
			NSLog(@"start waiting for downloaded page number: %ld", self->_currentPage);
			[self spTrigger:waitingForPredownloadedPage message:nil];
		}
	});
	return result;
}

- (void) addNextPageWithJSONAndCount:(SPPair*)JSONandCount
{
	__block NSArray *pageJSON = nil;
	dispatch_sync(_sync, ^{
		self->_currentPage++;
		self.pagesRemain = @([self.pagesRemain integerValue] - 1);
		pageJSON = JSONandCount.right;
	});
	[self addPageWithJSON:pageJSON];
}

@end
