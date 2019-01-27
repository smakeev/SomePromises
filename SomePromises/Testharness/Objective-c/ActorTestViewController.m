//
//  ActorTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 23/01/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "ActorTestViewController.h"
#import "SomePromise.h"

@actor(MyActor)

- (void) action;

@end

@implementation MyActor

- (void) action {
	NSLog(@"Action. Check the thread");
}

@end


@actor(MyMainActor)

- (void) mainAction;

@end

@implementation MyMainActor

- (void) mainAction {
	NSLog(@"Action. Check the thread is main");
}

@end

@interface ActorTestViewController ()

@end

@implementation ActorTestViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	MyActor *actor = [MyActor threadActor:[SomePromiseThread threadWithName:@"actorTestThread"]];
	MyMainActor *mainActor = [MyMainActor mainActor];
	[actor action];
	[mainActor mainAction];
}


@end
