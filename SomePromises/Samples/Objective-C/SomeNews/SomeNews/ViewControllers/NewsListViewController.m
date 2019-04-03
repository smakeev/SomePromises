//
//  NewsListViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NewsListViewController.h"
#import "ArticlesModelViewProtocol.h"
#import "ArticlesModel.h"
#import "NewsListTableViewCell.h"
#import "DownloadingTableViewCell.h"
#import "AlertsPresenterProtocol.h"
#import "AlertsPresenterProtocolStrategy.h"
#import "ContainerableProtocolStrategy.h"
#import "AppDelegate.h"
#import "UIImageViewWithDownloader.h"

#import "ShimmerAnimatedLabel.h"

#define kArticles @"_articlesToShow"

#define kCellMinHeight 120.0
#define kCellMaxHeight 350.0

#define kNoSelection -1
@protocol NewsListCellImageUpdater <NSObject>
- (void) imageTapped:(UITapGestureRecognizer*)sender;
@end;

@interface __IndexPathWrapper : NSObject

@property (nonatomic) NSInteger rowIndex;
@property (nonatomic) NSInteger sectionIndex;

@end

@implementation __IndexPathWrapper
@end

@interface NewsListViewController () <AlertsPresenterProtocol>
{
	NSObject<UITableViewDelegate, UITableViewDataSource, NewsListCellImageUpdater> *_delegate;
	IBOutlet UITableView *_table;
	
	@public
	NSMutableArray *_indexesOfUpdated;
}

@property (nonatomic) NSMutableArray<__IndexPathWrapper*> *extendedCells;
@property (nonatomic) __IndexPathWrapper *selectedCell;
@property (nonatomic) NSInteger selectedArticleIndex;
@property (nonatomic, weak) UIButton *currentSelectionButton;

@property (nonatomic) BOOL showDownloadingCell;

@end

@implementation NewsListViewController
@synthesize container;
@synthesize embededControllers;

+ (void) load
{
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    	[SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(AlertsPresenterProtocol) extention:[AlertsPresenterProtocolStrategy class] whereSelf:@protocol(NSObject)];
		[SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(Containerable) extention:[ContainerableProtocolStrategy class] whereSelf:@protocol(NSObject)];
    });
}

//@TODO:
- (UIView*) baseAlertView
{
	return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_table.delegate = _delegate;
	_table.dataSource = _delegate;
	
	UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	backgroundView.backgroundColor = [UIColor colorNamed:@"background"];
	_table.backgroundView = backgroundView;
	
	_table.refreshControl = [[UIRefreshControl alloc] init];
	[_table.refreshControl addTarget:self action:@selector(startRefreshing) forControlEvents:UIControlEventValueChanged];
	_table.refreshControl.backgroundColor = [UIColor colorNamed:@"background"];
	
	UIImageView *logoBG = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
	logoBG.contentMode = UIViewContentModeScaleAspectFit;
	logoBG.translatesAutoresizingMaskIntoConstraints = NO;
	[_table.refreshControl addSubview:logoBG];
	[_table.refreshControl addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[logoBG]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(logoBG)]];
	[_table.refreshControl addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[logoBG]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(logoBG)]];
	[_table.refreshControl sendSubviewToBack:logoBG];
	
	_indexesOfUpdated = [NSMutableArray new];
}

- (void) startRefreshing
{
	[((AppDelegate*)([UIApplication sharedApplication].delegate)) startUpdate];
}

- (void) setupWithViewModel:(id<ArticlesModelViewProtocol>)viewModel
{
	_selectedArticleIndex = kNoSelection;
	self.extendedCells = [NSMutableArray new];
	__weak NewsListViewController *weakListControllerRef = self;

	_delegate =  [SomePromiseObject createObjectBasedOn:[NSObject class]
												protocols:@[@protocol(UITableViewDelegate),
														  @protocol(UITableViewDataSource),
														  @protocol(NewsListCellImageUpdater)]
										   bindLifetimeTo:nil
											   definition:^(SomePromiseObject* creator) {
							
							 [creator create:@selector(numberOfSectionsInTableView:) with:^NSInteger(NSObject *self, UITableView *table){
								 	if(weakListControllerRef.viewType == EViewType_TOP)
										return 1;
								 
								 	SPArray *array = self.spGet(kArticles);
									return array.count;
							 }];

							//data source
							 [creator create:@selector(tableView:numberOfRowsInSection:) with:^NSInteger(NSObject *self, UITableView *table, NSInteger section){
									SPArray *array = self.spGet(kArticles);
								 	if(weakListControllerRef.viewType == EViewType_TOP)
								 	{
								 		if(weakListControllerRef.showDownloadingCell)
								 		{
											return array.count + 1;
										}
										return array.count;
									}
								 	return ((SPArray*)(array[section].value)).count;
							 }];
							 
							[creator create:@selector(imageTapped:) with:^(NSObject *self, UITapGestureRecognizer *sender){
								NSString *additionalText = nil;
								UIImageView *target = (UIImageView*)sender.view;
								if(target.spHas(@"_errorText"))
								{
									additionalText = target.spGet(@"_errorText");
								}
								[weakListControllerRef showAlertViewWithContentView:^UIView*(CGSize desiredSize){
									UIView *targetView = [weakListControllerRef whereToPresent];
									CGSize size = targetView.frame.size;
									UIView *board = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width * 0.8, size.height * 0.4)];
									board.backgroundColor = [UIColor whiteColor];
									UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectZero];
									UIImage *image = target.image;
									
  									[board addSubview:icon];
									icon.translatesAutoresizingMaskIntoConstraints = NO;
									
									icon.contentMode = UIViewContentModeScaleAspectFit;
									
									[board addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[icon]-20-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(icon)]];
									[board addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[icon]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(icon)]];
									
									if(additionalText)
									{
										icon.image = [UIImage imageNamed:@"Logo"];
										ShimmerAnimatedLabel *imageText = [[ShimmerAnimatedLabel alloc] initWithFrame:CGRectZero];
										imageText.translatesAutoresizingMaskIntoConstraints = NO;
										[icon addSubview:imageText];
										[imageText.centerXAnchor constraintEqualToAnchor:icon.centerXAnchor].active = YES;
										[imageText.topAnchor  constraintEqualToAnchor:icon.topAnchor].active = YES;
										
										imageText.text = additionalText;
									}
									else
									{
										icon.image = image;
									}
									
									board.layer.cornerRadius = 30.0;
									board.layer.masksToBounds = NO;
									board.layer.shouldRasterize = YES;
									board.layer.rasterizationScale = [UIScreen mainScreen].scale;
									return board;
								}];
							}];

							[creator create:@selector(tableView:cellForRowAtIndexPath:) with:^UITableViewCell*(NSObject *self, UITableView *table, NSIndexPath *indexPath){
								

								SPArray *array = self.spGet(kArticles);
								if(weakListControllerRef.viewType == EViewType_TOP &&
									weakListControllerRef.showDownloadingCell == YES &&
									indexPath.row == array.count)
								{
									DownloadingTableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"DownloadingCell"];
									[cell.activityControll startAnimating];
									return cell;
								}
								
								NewsListTableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"NewsCellID"];
								
								ArticleItem *item = nil;
								if(weakListControllerRef.viewType == EViewType_TOP)
								{
									item = array[indexPath.row].value;
								}
								else
								{
									SPArray *items = array[indexPath.section].value;
									item = items[indexPath.row].value;
								}

								NSString *urlToImage = [@asMaybe(item.imageUrl, [NSString class]) getOrElse:@""];
								if ([cell updateImageWithUrl:urlToImage]) {
									cell.image.owner = cell;
									cell.image.imageUrl = urlToImage;
								}

								if(item.imageErrorText)
								{
									if(cell.image.spHas(@"_errorText"))
									{
										cell.image.spSet(@"_errorText", item.imageErrorText);
									}
									else
									{
										cell.image.spExtend(@"_errorText", item.imageErrorText, nil, nil);
									}
								}
								else if(cell.image.spHas(@"_errorText"))
								{
									cell.image.spUnset(@"_errorText");
								}
								if([cell.image.gestureRecognizers count] == 0)
								{
									UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
									[cell.image addGestureRecognizer:recognizer];
								}
								
								cell.header.text = [@asMaybe(item.title, [NSString class]) getOrElse:@""];
								cell.text.text = [@asMaybe(item.articleDescription, [NSString class]) getOrElse:@""];
								if([cell.text.text isEqualToString:@""])
								{
									cell.text.text =  [@asMaybe(item.content, [NSString class]) getOrElse:@""];
								}
								cell.info.text = [@asMaybe(item.date, [NSString class]) getOrElse:@""];

								__IndexPathWrapper *indexPathWrapper = [[__IndexPathWrapper alloc] init];
								indexPathWrapper.rowIndex = indexPath.row;
								indexPathWrapper.sectionIndex = indexPath.section;
								if(cell.extendCell.spHas(exIndexPath))
								{
									cell.extendCell.spSet(exIndexPath, indexPathWrapper);
								}
								else
								{
									cell.extendCell.spExtend(exIndexPath, indexPathWrapper, nil, nil);
								}

								cell.extendCell.enabled = cell.text.text.length ? YES : NO;

								UIImage *newImage = nil;
								BOOL extended = NO;
								for(__IndexPathWrapper *wrapper in  weakListControllerRef.extendedCells)
								{
									if(wrapper.rowIndex == indexPath.row && wrapper.sectionIndex == indexPath.section)
									{
										extended = YES;
										break;
									}
								}
								if(extended)
								{
									newImage = [UIImage imageNamed:@"arrowUP"];
								}
								else
								{
									newImage = [UIImage imageNamed:@"arrowDown"];
								}
								[cell adjustConstraintsToExtended:extended];
								[cell.extendCell setImage:newImage forState:UIControlStateNormal];

								cell.indexOfAarticle = item.index;

								if(!cell.openInSafari.spHas(@"_articleURL"))
								{
									cell.openInSafari.spExtend(@"_articleURL", item.url, nil, nil);
								}
								else
								{
									cell.openInSafari.spSet(@"_articleURL", item.url);
								}

								if(cell.open.spHas(@"_urlToOpen"))
								{
									cell.open.spSet(@"_urlToOpen", item.url);
								}
								else
								{
									cell.open.spExtend(@"_urlToOpen", item.url, nil, nil);
								}

								if(cell.open.spHas(@"_articleIndex"))
								{
									cell.open.spSet(@"_articleIndex", @(item.index));
								}
								else
								{
									cell.open.spExtend(@"_articleIndex", @(item.index), nil, nil);
								}

								if(cell.open.spHas(@"_cellIndexPath"))
								{
									cell.open.spSet(@"_cellIndexPath", indexPathWrapper);
								}
								else
								{
									cell.open.spExtend(@"_cellIndexPath", indexPathWrapper, nil, nil);
								}

								if(weakListControllerRef.selectedArticleIndex == item.index)
								{
									[cell.open setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
									weakListControllerRef.currentSelectionButton = cell.open;
									weakListControllerRef.selectedCell = indexPathWrapper;
								}
								else
								{
									[cell.open setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
								}

								return cell;
							}];
							
							[creator create:@selector(tableView:heightForRowAtIndexPath:) with:^CGFloat(NSObject *self, UITableView *table, NSIndexPath *indexPath){
									for(__IndexPathWrapper *extended in weakListControllerRef.extendedCells)
									{
										if(extended.rowIndex == indexPath.row && extended.sectionIndex == indexPath.section)
										{
											return kCellMaxHeight;
										}
									}
									return kCellMinHeight;
							}];
							
							[creator create:@selector(tableView:viewForHeaderInSection:) with:^UIView*(NSObject *self, UITableView *table, NSInteger section){
								if(weakListControllerRef.viewType == EViewType_TOP)
								{
									return nil;
								}
								
								ShimmerAnimatedLabel *label = [[ShimmerAnimatedLabel alloc] initWithFrame:CGRectZero];
								SPArray *array = self.spGet(kArticles);
								
								SPArray *items = array[section].value;
								if(items.count == 0)
									return nil;
								ArticleItem *item = items[0].value;
								label.text = [NSString stringWithFormat:@"   %@", item.sourceName];
								label.backgroundColor = [UIColor colorNamed:@"background"];
								return label;
							}];
	
							[creator create:@selector(tableView:willDisplayCell:forRowAtIndexPath:) with:^(NSObject *self, UITableView *table, UITableViewCell *cell, NSIndexPath *indexPath){
								__strong NewsListViewController *strongListControllerRef = weakListControllerRef;
								guard(strongListControllerRef) else {return;}
								if(weakListControllerRef.viewType == EViewType_TOP &&
									weakListControllerRef.showDownloadingCell == NO)
								{
									for(NSNumber *index in strongListControllerRef->_indexesOfUpdated)
									{
										if(index.integerValue == indexPath.row)
										{
											return; //don't update second time for the same cell index.
										}
									}

									SPArray *array = self.spGet(kArticles);
									if(indexPath.row == array.count - 1 && (indexPath.row + 1) % [Services.user.pageSize integerValue] == 0)
									{
										[strongListControllerRef->_indexesOfUpdated addObject:@(indexPath.row)];
										//send signal to start update.
										SomePromiseSignal *signalAddNewPageIfExists = [[SomePromiseSignal alloc] initWithName:readyToGetNewPage tag:0 message:nil anythingElse:nil];
										NSMutableSet *receivers = [NSMutableSet new];
										[weakListControllerRef getAllAboveContainersForController:weakListControllerRef set:receivers];
										[receivers removeObject:self]; //don't send to ourself
										[weakListControllerRef sendSignal:signalAddNewPageIfExists toObject:receivers.allObjects];
									}
								}
							}];
							
							
							[creator create:@selector(tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:) with:^(NSObject *self, UITableView *table, NSIndexPath *indexPath){
								SPArray *array = self.spGet(kArticles);
								ArticleItem *item = nil;
								if(weakListControllerRef.viewType == EViewType_TOP)
								{
									item = array[indexPath.row].value;
								}
								else
								{
									item = ((SPArray*)array[indexPath.section].value)[indexPath.row].value;
								}
								
								UIContextualAction *getArticleUrl = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction *action,  UIView *sourceView, void (^ completionHandler)(BOOL)) {
									__strong NewsListViewController *strongListControllerRef = weakListControllerRef;
									guard(strongListControllerRef) else {return;}
									NSArray* sharedObjects=[NSArray arrayWithObjects:item.url,  nil];
									UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:sharedObjects applicationActivities:nil];
									activityViewController.popoverPresentationController.sourceView = strongListControllerRef.view;
									[strongListControllerRef presentViewController:activityViewController animated:YES completion:nil];
									completionHandler(YES);
								}];
								
								getArticleUrl.backgroundColor = [UIColor darkGrayColor];
								getArticleUrl.image = [UIImage imageNamed:@"copylink"];
								
								UIContextualAction *getImageUrl = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Copy Image URL" handler:^(UIContextualAction *action,  UIView *sourceView, void (^ completionHandler)(BOOL)) {
									UIPasteboard *pb = [UIPasteboard generalPasteboard];
									[pb setString:item.imageUrl];
									completionHandler(YES);
								}];
								getImageUrl.backgroundColor = [UIColor colorNamed:@"PulsingLayerColor"];
								getImageUrl.image = [UIImage imageNamed:@"icon"];
								UIContextualAction *articleAction;
								
								UIContextualAction *addArticleToArchive =  [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Add To Archive" handler:^(UIContextualAction *action,  UIView *sourceView, void (^ completionHandler)(BOOL)) {
									//@TODO:
									completionHandler(YES);
								}];
								addArticleToArchive.backgroundColor = [UIColor colorNamed:@"background"];
								addArticleToArchive.image = [UIImage imageNamed:@"archive"];
								
								
								//UIContextualAction *removeArticleFromArchive;
								articleAction = addArticleToArchive;
								return [UISwipeActionsConfiguration configurationWithActions:@[articleAction, getArticleUrl, getImageUrl]];
							}];
				  }];
	
	[_delegate spExtend:kArticles defaultValue:nil setter:nil getter:nil];

	if(self.viewType == EViewType_TOP)
	{
		_delegate.spSet(kArticles, [viewModel.articlesToShow copy]);
	}
	else
	{
		_delegate.spSet(kArticles, [viewModel.articlesToShowBySources copy]);
	}
	
	void (^updateAction)(SPArray *articlesToShow) = nil;
	@sp_avoidblockretain(self)
	updateAction = ^(SPArray *articlesToShow){
			@sp_strongify(self)
			guard(self) else {return;}
			dispatch_async(dispatch_get_main_queue(), ^{
				@sp_strongify(self)
				guard(self) else {return;}
				self->_delegate.spSet(kArticles, [articlesToShow copy]);
				if([self->_table.refreshControl isRefreshing])
				{
					[self.extendedCells removeAllObjects];
					[self->_table.refreshControl endRefreshing];
					[self->_indexesOfUpdated removeAllObjects];
				}
				[self->_table reloadData];
			});
		};
	@sp_avoidend(self)
	
	if(self.viewType == EViewType_TOP)
	{
		@sp_start(sp_action(_delegate, [updateAction copy])) = @sp_observe(viewModel, articlesToShow);
		viewModel.downloadingNewPage.bind(self, ^(NSNumber *value){
			dispatch_async(dispatch_get_main_queue(), ^{
				self.showDownloadingCell = [value boolValue];
				[self->_table reloadData];
			});
		});
	}
	else
	{
		@sp_start(sp_action(_delegate, [updateAction copy])) = @sp_observe(viewModel, articlesToShowBySources);
	}
}

- (IBAction)extendButtonPressed:(UIButton*)sender
{
	__block NSInteger indexToDelete = -1;
	__IndexPathWrapper *fromButton = sender.spGet(exIndexPath);
	[self.extendedCells enumerateObjectsUsingBlock:^(__IndexPathWrapper *obj, NSUInteger idx, BOOL *stop) {
		if(obj.rowIndex == fromButton.rowIndex &&
			obj.sectionIndex == fromButton.sectionIndex)
		{
			indexToDelete = idx;
			*stop = YES;
		}
	}];
	UIImage *newImage = nil;
	if(indexToDelete == -1)
	{
		[self.extendedCells addObject:fromButton];
		newImage = [UIImage imageNamed:@"arrowUP"];
	}
	else
	{
		[self.extendedCells removeObjectAtIndex:indexToDelete];
		newImage = [UIImage imageNamed:@"arrowDown"];
	}

	[UIView animateWithDuration:0.5 animations:^{
				sender.transform = CGAffineTransformMakeRotation(M_PI);
	} completion:^(BOOL finished) {
				sender.transform = CGAffineTransformIdentity;
				[sender setImage:newImage forState:UIControlStateNormal];
	}];

	[self->_table beginUpdates];
	[self->_table endUpdates];
}

- (void) deselectArticle
{
	NSArray *visibleRows = [_table indexPathsForVisibleRows];
	BOOL selectedCellVisible = NO;
	for(NSIndexPath *indexPath in visibleRows)
	{
		if(indexPath.row == self.selectedCell.rowIndex &&
				indexPath.section == self.selectedCell.sectionIndex)
		{
			selectedCellVisible = YES;
			break;
		}
	}

	void (^completionBlock)(void) = ^ {
		self.selectedCell = nil;
		self.selectedArticleIndex = -1;
		self.currentSelectionButton = nil;
	};

	if(selectedCellVisible)
	{
		[UIView animateWithDuration:0.5 animations:^{
			self.currentSelectionButton.transform = CGAffineTransformMakeRotation(M_PI);
		} completion:^(BOOL finished) {
			self.currentSelectionButton.transform = CGAffineTransformIdentity;
			[self.currentSelectionButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
			completionBlock();
		}];
	}
	else
	{
		completionBlock();
	}

}

- (IBAction)openWebControllerPressed:(UIButton *)sender
{
	UIImage *newImage = nil;
	UIImage *newImageForPrevButton = nil;
	NSString *urlToOpen = nil;
	if(sender.spHas(@"_urlToOpen"))
	{

		urlToOpen = sender.spGet(@"_urlToOpen");
	}
	
	NSInteger articleIndex = [sender.spGet(@"_articleIndex") integerValue];
	
	__IndexPathWrapper *prevSelectedCell = self.selectedCell;
	
	if(_selectedArticleIndex == articleIndex)
	{
		newImage = [UIImage imageNamed:@"arrowRight"];
		newImageForPrevButton = [UIImage imageNamed:@"arrowLeft"];
		_selectedArticleIndex = -1;
		self.currentSelectionButton = nil;
		self.selectedCell = nil;
	}
	else
	{
		newImage = [UIImage imageNamed:@"arrowLeft"];
		newImageForPrevButton = [UIImage imageNamed:@"arrowRight"];
		_selectedArticleIndex = articleIndex;
		if(self.currentSelectionButton == nil)
		{
			self.currentSelectionButton = sender;
		}
		self.selectedCell = sender.spGet(@"_cellIndexPath");
	}

	
	NSArray *visibleRows = [_table indexPathsForVisibleRows];

	BOOL rotateOldArrow = NO;
	if(prevSelectedCell)
	{
		for(NSIndexPath *indexPath in visibleRows)
		{
			if(indexPath.row == prevSelectedCell.rowIndex &&
				indexPath.section == prevSelectedCell.sectionIndex)
			{
				rotateOldArrow = YES;
				break;
			}
		}
	}
	
	//sending signal
	SomePromiseSignal *signalSelectArticle = [[SomePromiseSignal alloc] initWithName:selectArticle tag:0 message:@{@"articleID" : @(_selectedArticleIndex), @"url" : urlToOpen ? : @"Empty"} anythingElse:nil];
	NSMutableSet *receivers = [NSMutableSet new];
	[self getAllAboveContainersForController:self set:receivers];
	
	[receivers removeObject:self]; //don't send to ourself
	
	[self sendSignal:signalSelectArticle toObject:receivers.allObjects];

	[UIView animateWithDuration:0.5 animations:^{
				sender.transform = CGAffineTransformMakeRotation(M_PI);
				if(self.currentSelectionButton && self.currentSelectionButton != sender && rotateOldArrow)
				{
					self.currentSelectionButton.transform = CGAffineTransformMakeRotation(M_PI);
				}
	} completion:^(BOOL finished) {
				sender.transform = CGAffineTransformIdentity;
				self.currentSelectionButton.transform = CGAffineTransformIdentity;
				[sender setImage:newImage forState:UIControlStateNormal];
		
				if(self.currentSelectionButton != nil && self.currentSelectionButton != sender)
				{
					[self.currentSelectionButton setImage:newImageForPrevButton forState:UIControlStateNormal];
					self.currentSelectionButton = sender;
				}
		
		
	}];
}

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{
	if([signal.name isEqualToString:selectArticle])
	{
		return YES;
	}
	if([signal.name isEqualToString:unselectArticle])
	{
		return YES;
	}
	
	return NO;
}

 - (void)handleTheSignal:(SomePromiseSignal*)signal
 {
 	if([signal.name isEqualToString:selectArticle])
 	{
		self.selectedArticleIndex = [signal.message[@"articleID"] integerValue];
		[_table reloadData];
	}
	
	if([signal.name isEqualToString:unselectArticle])
	{
		[self deselectArticle];
	}
 }


@end
