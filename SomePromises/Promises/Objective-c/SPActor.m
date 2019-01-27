//
//  SPActor.m
//  SomePromises
//
//  Created by Sergey Makeev on 23/01/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "SPActor.h"
#import "SomePromiseThread.h"
#import <objc/runtime.h>

@interface __SPActorWorker : NSProxy
{
	SPActor *_actor;
}
+ (__SPActorWorker*) makeWithActor:(SPActor*)actor;

@end

@interface SPActor()
{
	dispatch_queue_t _queue;
	SomePromiseThread *_thread;
}

@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) SomePromiseThread *thread;

@end

@implementation SPActor

+ (instancetype) queueActor:(dispatch_queue_t) queue {
	SPActor *_self = [[self alloc] init];
	
	if (_self) {
		_self->_queue = queue;
	}
	return (SPActor*)[__SPActorWorker makeWithActor:_self];
}

+ (instancetype) threadActor:(SomePromiseThread*)thread {
	SPActor *_self = [[self alloc] init];
	if (_self) {
		_self->_thread = thread;
	}
	return (SPActor*)[__SPActorWorker makeWithActor:_self];
}

+ (instancetype) mainActor {
	return [self queueActor:dispatch_get_main_queue()];
}

@end

@implementation __SPActorWorker

+ (__SPActorWorker*) makeWithActor:(SPActor*)actor {
	__SPActorWorker *worker = [__SPActorWorker alloc];
	worker->_actor = actor;
	return worker;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self->_actor respondsToSelector:aSelector];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [self->_actor isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return [self->_actor isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [self->_actor conformsToProtocol:aProtocol];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
	NSMethodSignature* signature = [self->_actor methodSignatureForSelector:sel];
	return signature;
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	const char* returnType = [invocation.methodSignature methodReturnType];
	
	if (returnType[0] == _C_CONST) returnType++;
	if (strcmp(returnType, @encode(void)) != 0 )
	{
		NSLog(@"SomePromise Warning: Actor object used for calling method with not void return type.");
	}

	if(self->_actor.thread) {
		[self->_actor.thread performBlock:^{
			[invocation invokeWithTarget:self->_actor];
		}];
	} else {
		dispatch_async(self->_actor.queue, ^{
			[invocation invokeWithTarget:self->_actor];
		});
	}
}

@end
