//
//  SourcesViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 19/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SourcesViewController.h"

@interface SourcesViewController ()
{
	NSMutableArray *_availableSources;
	SomePromise *_getSourcesPromise;
}
@end

@implementation SourcesViewController

- (void) handleSources:(NSArray*)sources
{
	
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_getSourcesPromise reject];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	_availableSources = [NSMutableArray new];
	NSObject<NetServiceProviderProtocol> *serviceNet = Services.net;
	_getSourcesPromise = [serviceNet getSources].onSuccess(^(id result){
		NSLog(@"result: %@", result);
		[self handleSources:result[@"sources"]];
	}).onReject(^(NSError *error){
		//@TODO:
	});
}

@end
