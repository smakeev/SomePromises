//
//  ArticlesModelView.m
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ArticlesModelView.h"
#import "ArticlesModel.h"

@interface ArticlesModelView ()
{
	SPArray<SPArray*> *_articlesRepresentaition; //grouped by sources articles.
	SPArray *_articlesToShow;
	SPArray *_articlesToShowBySources;
	dispatch_queue_t _sync;
}

@property (atomic) SPArray *articlesToShow;
@property (atomic) SPArray *articlesToShowBySources;

@end

@implementation ArticlesModelView
@synthesize downloadingNewPage = _downloadingNewPage;

- (instancetype) initWithModel:(ArticlesModel*)articles
{
	self = [super init];
	if(self)
	{
		_downloadingNewPage = [SomeClassBox empty];
		_sync = dispatch_queue_create("modelViewSyncQueue", DISPATCH_QUEUE_SERIAL);
		_articlesRepresentaition = [SPArray new];
		
		@sp_avoidblockretain(self)
		articles.spOnOnQueue(waitingForPredownloadedPage, _sync, self, ^(NSDictionary *msg){
			@sp_strongify(self)
			guard(self) else {return;}
			self.downloadingNewPage.value = @(YES);
			NSLog(@"§§§ downloading start");
		});

		articles.spOnOnQueue(expectedPredownloadedPageCame, _sync, self, ^(NSDictionary *msg){
			@sp_strongify(self)
			guard(self) else {return;}
			NSLog(@"§§§ downloading done");
			self.downloadingNewPage.value = @(NO);
		});

		articles.spOnOnQueue(modelRecreated, _sync, self, ^(NSDictionary *msg){
			@sp_strongify(self)
			guard(self) else {return;}
			self->_articlesRepresentaition = [SPArray new];
			self.articlesToShow = [SPArray new];
			self.articlesToShowBySources = [SPArray new];
		});
		
		articles.spOnOnQueue(modelArticleAdded, _sync, self, ^(NSDictionary *msg){
			@sp_strongify(self)
			guard(self) else {return;}
			ArticleItem *item = msg[@"article"];
			
			__block SPArray *whereToPlace = nil;
			[self->_articlesRepresentaition enumerateObjectsUsingBlock:^(SPArray *obj, NSUInteger idx, BOOL *stop)
			{
				SPArray *array = obj;
				ArticleItem *firstItem = array[0].value;
				if([firstItem.sourceId isEqualToString:item.sourceId])
				{
					whereToPlace = array;
					*stop = YES;
				}
			}];
			
			if(whereToPlace == nil)
			{
				whereToPlace = [SPArray new];
				whereToPlace.autoshrink = YES;
				[self->_articlesRepresentaition add:whereToPlace];
			}
			[whereToPlace addWeakly:item];
			
			self.articlesToShow = [self.articlesToShow addedWeakly:item];
			self.articlesToShowBySources = [self->_articlesRepresentaition copy];
			
		});
		
		articles.spOn(stopUpdate, self, ^(NSDictionary *msg) {
			[self spTrigger:stopUpdate message:nil];
		});
		@sp_avoidend(self)
	}

	return self;
}

@end
