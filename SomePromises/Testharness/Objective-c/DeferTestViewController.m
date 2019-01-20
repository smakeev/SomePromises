//
//  DeferTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 19/05/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "DeferTestViewController.h"
#import "SomePromise.h"


@interface DeferTestViewController ()

@end

@implementation DeferTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    defer(0, ^{
       NSLog(@"Defer code from View did load");
	});
	
	defer(1, ^{
       NSLog(@"Defer code from View did load");
	});
	NSLog(@"End of Did Load");
}

- (IBAction)deferTest:(id)sender
{
   deferLevelTag(secondTag)

   externalDefer(firstTag, 0, ^{
	   NSLog(@"firstTag Defer code 0");
   });
	
   externalDefer(firstTag, 1, ^{
		 NSLog(@"firstTag Defer code 1");
   });
	
   deferLevelTag(firstTag)
	
   externalDefer(secondTag, 0, ^{
	  NSLog(@"Second Tag:");
   });
	
   externalDefer(promiseTag, 0, ^{
	  NSLog(@"promiseTag:");
   });
	
   [[SomePromise postpondedPromiseWithName:@"promise for defer test"
	                     onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	                     delegate:nil
	                     delegateQueue:nil
					 resolvers:^(BaseBlocks(FulfillBlock, rejectBlock))
					 {
					         deferLevelTag(promiseTag)
						     for(int i = 0; i < 10; ++i)
						     {
						         sleep(1);
							 }
							 rejectBlock(nil);
					 } class: nil] start];
}

@end
