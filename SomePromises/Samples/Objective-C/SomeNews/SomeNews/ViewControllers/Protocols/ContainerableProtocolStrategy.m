//
//  ContainerableProtocolStrategy.m
//  SomeNews
//
//  Created by Sergey Makeev on 16/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ContainerableProtocolStrategy.h"

@interface ContainerableProtocolStrategy ()

@end

@implementation ContainerableProtocolStrategy
@dynamic container;
@dynamic embededControllers;

- (void) getAllAboveContainersForController:(UIViewController<Containerable>*)controller set:(NSMutableSet*)set
{
	if(controller.container)
	{
		[set addObject:controller.container];
	}
	if(controller.container.embededControllers)
	{
		[controller.container.embededControllers enumerateObjectsUsingBlock:^(UIViewController<Containerable> *obj, NSUInteger idx, BOOL *stop) {
			[set addObject:obj];
		}];
	}
	if(!controller.container)
		return;
	[self getAllAboveContainersForController:controller.container set:set];
}

- (void) getAllReceiversForController:(UIViewController<Containerable>*)controller set:(NSMutableSet*)set
{
	[set addObject:controller];
	if(controller.container && ![set containsObject:controller.container])
	{
		[self getAllReceiversForController:controller.container set:set];
	}
	
	if(controller.embededControllers)
	{
		[controller.embededControllers enumerateObjectsUsingBlock:^(UIViewController<Containerable> *obj, NSUInteger idx, BOOL *stop) {
			[set addObject:obj];
			[self getAllReceiversForController:obj set:set];
		}];
	}
}

- (UIView*) whereToPresentContainerable
{
	UIViewController<Containerable> *target = self;
	while (target.container)
	{
		target = target.container;
	}
	return target.view;
}

@end
