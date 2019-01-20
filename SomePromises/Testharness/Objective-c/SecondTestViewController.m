//
//  SecondTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 15/01/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SecondTestViewController.h"
#import "SomePromise.h"


@class Observer;

static NSString* statusAsString(PromiseStatus status)
{
   switch (status)
   {
	  case ESomePromiseUnknown:
		   return @"Unknown";
      case ESomePromiseNonActive:
		   return @"NonActive";
      case ESomePromisePending:
		   return @"Pending";
      case ESomePromiseSuccess:
		   return @"Success";
      case ESomePromiseRejected:
           return @"Rejected";
   }
	
   return nil;
}

@interface ObserverCell: UITableViewCell

@property (nonatomic, weak) Observer *observer;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

- (void)setStatus:(NSString*)status;
- (void)setResult:(NSString*)result;
- (void)setPromiseProgress:(NSInteger)progress;

@end

@implementation ObserverCell

- (void)setStatus:(NSString*)status
{
   self.statusLabel.text = status;
}

- (void)setResult:(NSString*)result
{
    self.resultLabel.text = result;
}

- (void)setPromiseProgress:(NSInteger)progress
{
   self.progress.progress = (float) progress / 100;
}

@end


@interface Observer: NSObject <SomePromiseObserver>
@property (nonatomic, weak) ObserverCell *cell;
@end

@implementation Observer
- (void) promise:(SomePromise*_Nonnull) promise gotResult:(id _Nonnull ) result
{
   [self.cell setResult:[result description]];
}

- (void) promise:(SomePromise*_Nonnull) promise rejectedWithError:(NSError*_Nullable) error
{
   [self.cell setResult:[NSString stringWithFormat:@"Rejected with error %@", error.localizedDescription]];
}

- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
   switch (newStatus)
   {
	  case ESomePromiseUnknown:
		   [self.cell setStatus:@"Unknown"];
		   break;
      case ESomePromiseNonActive:
		   [self.cell setStatus:@"NonActive"];
           break;
      case ESomePromisePending:
		   [self.cell setStatus:@"Pending"];
           break;
      case ESomePromiseSuccess:
		   [self.cell setStatus:@"Success"];
           break;
      case ESomePromiseRejected:
           [self.cell setStatus:@"Rejected"];
           break;
   }
}

- (void) promise:(SomePromise*_Nonnull) promise progress:(float) progress
{
   [self.cell setPromiseProgress:progress];
}
@end

@interface SecondTestViewController () <SomePromiseDelegate, UITableViewDataSource>

@end

@implementation SecondTestViewController
{
	__weak IBOutlet UIButton *createButton;
	__weak IBOutlet UIButton *createStartButton;
	__weak IBOutlet UIButton *startButton;
	__weak IBOutlet UIButton *rejectButton;
	__weak IBOutlet UIProgressView *progressBar;
	__weak IBOutlet UIActivityIndicatorView *progressIndicator;
	__weak IBOutlet UIButton *clearButton;
	__weak IBOutlet UITableView *tableView;
	SomePromise *promise;
	NSMutableArray *_observers;
}

- (IBAction)createPromise:(id)sender
{
	promise = [SomePromise postpondedPromiseWithName:@"Second Test Promise"
	                     onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	                     delegate:self
	                     delegateQueue:dispatch_get_main_queue()
					 resolvers:^(AllBlocksWithNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock))
					 {
						     for(int i = 1; i <= 100; ++i)
						     {
								 if (isRejectedBlock())
						         {
									 return;
								 }
						         sleep(1);
						         progressBlock(i);
							 }
							 fulfillBlock(@"RESULT");
					 } class: nil];
}

- (IBAction)createAndStart:(id)sender
{
	promise = [SomePromise promiseWithName:@"Second Test Promise"
	                     onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	                     delegate:self
	                     delegateQueue:dispatch_get_main_queue()
					 resolvers:^(AllBlocksWithNames(fulfillBlock, rejectBlock, isRejectedBlock, progressBlock))
					 {
						     for(int i = 1; i <= 100; ++i)
						     {
						         if (isRejectedBlock())
						         {
									 return;
								 }
								 
						         sleep(1);
								 progressBlock(i);
							 }
							 fulfillBlock(@"RESULT");
					 } class: nil];
}

- (IBAction)startPromise:(id)sender
{
    [promise start];
}

- (IBAction)rejectPromise:(id)sender
{
   [promise reject];
}

- (IBAction)clearPressed:(id)sender
{
   [promise reject];
   promise = nil;
   createButton.enabled = YES;
   createStartButton.enabled = YES;;
   startButton.enabled = NO;
 //  rejectButton.enabled = NO;
   progressBar.progress = 0;
   progressIndicator.hidden = YES;
   progressBar.tintColor = UIColor.blueColor;
   clearButton.hidden = YES;
   _observers = [NSMutableArray new];
   [tableView reloadData];
}

- (IBAction)AddObserverPressed:(id)sender
{
    if (promise ==  nil)
    {
        return;
	}
    Observer *newObserver = [[Observer alloc] init];
    [promise addObserverOnMain:newObserver];
    [_observers addObject:newObserver];
    [tableView reloadData];
}


- (void)viewWillAppear:(BOOL)animated
{
   [self clearPressed:nil];
   [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
   [promise reject];
   [super viewWillDisappear:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_observers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ObserverCell *cell =  (ObserverCell*)[tableView dequeueReusableCellWithIdentifier:@"ObserverCell"];
	cell.observer = _observers[indexPath.row];
	cell.observer.cell = cell;
	
	//initial values:
	[cell setPromiseProgress:promise.progress];
	[cell setStatus:statusAsString(promise.status)];
	if (ESomePromisePending == promise.status)
	{
		[cell setResult:@"in progress"];
	}
	else if (ESomePromiseSuccess == promise.status)
	{
	    [cell setResult:[promise.result description]];
	}
	else if (ESomePromiseRejected == promise.status)
	{
	    [cell setResult:[NSString stringWithFormat:@"Rejected with error %@", promise.error.localizedDescription]];
	}
	else
	{
		[cell setResult:@"..."];
	}
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
		[promise removeObserver:_observers[indexPath.row]];
		[_observers removeObjectAtIndex:indexPath.row];
		[tableView beginUpdates];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }
}


- (void) promise:(SomePromise*_Nonnull) promise gotResult:(id _Nonnull ) result
{
	clearButton.hidden = NO;
	progressIndicator.hidden = YES;
}

- (void) promise:(SomePromise*_Nonnull) promise rejectedWithError:(NSError*_Nullable) error
{
    clearButton.hidden = NO;
    progressBar.tintColor = UIColor.redColor;
    progressIndicator.hidden = YES;
}

- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
    if (ESomePromiseNonActive == newStatus)
    {
         progressBar.tintColor = UIColor.blueColor;
		 createButton.enabled = NO;
         createStartButton.enabled = NO;
         startButton.enabled = YES;
       //  rejectButton.enabled = YES;
	}
	
	if (ESomePromisePending == newStatus)
	{
	     startButton.enabled = NO;
	     progressIndicator.hidden = NO;
	}
	
	if (ESomePromiseSuccess == newStatus || ESomePromiseRejected == newStatus)
	{
	   // rejectButton.enabled = NO;
	}
	
}

- (void) promise:(SomePromise*_Nonnull) promise progress:(float) progress
{
    progressBar.progress = progress / 100;
}

@end
