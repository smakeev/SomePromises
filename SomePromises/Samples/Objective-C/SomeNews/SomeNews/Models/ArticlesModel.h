//
//  ArticlesModel.h
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArticleItem : NSObject

@property (nonatomic, readonly) NSString *sourceId;
@property (nonatomic, readonly) NSString *sourceName;
@property (nonatomic, readonly) NSString *author;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *articleDescription;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSString *imageUrl;
@property (nonatomic, readonly) NSString *date;
@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) NSInteger index;

+ (instancetype) createWithJSON:(NSDictionary*)JSON index:(NSInteger)index;

@end


@interface ArticlesModel : NSObject
{
	SPArray<ArticleItem*> *_articles;
	SPArray<NSArray*> *_JSONPages;
}

@property (atomic) NSNumber *pagesRemain;
@property (nonatomic) SPEventExpector *pageExpector;

+ (instancetype) new;
- (void) reset;
- (void) recreateWithFirstPageAndTotalElementsCount:(SPPair*)JSONandCount; //recreates the model.
- (SPPair*) getNextPage;
- (void) addNextPageWithJSONAndCount:(SPPair*)JSONandCount;
- (void) recallSubscribers;

@end
