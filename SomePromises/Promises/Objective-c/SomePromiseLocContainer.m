//
//  SomePromiseLocContainer.m
//  SomePromises
//
//  Created by Sergey Makeev on 29/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseLocContainer.h"
#import "SomePromiseFuture.h"
#import "SomePromiseThread.h"
#import "SomePromiseUtils.h"

@interface SPFabric() <SPProducer>
{
    NSMutableDictionary<NSString*, id> *_registeredParameters;
    NSDictionary<NSString*, id> *_tmpParams;
    NSMutableDictionary<NSString*, ProducingBlock> *_producingTable; //NSString - class name
}
@end

@implementation SPFabric

- (NSDictionary*) parameters
{
    guard (_tmpParams) else {return [_registeredParameters copy];}
    NSMutableDictionary *paramsToReturn = [_registeredParameters mutableCopy];
	for(NSString *key in _tmpParams.allKeys)
	{
		paramsToReturn[key] = _tmpParams[key];
	}
	return paramsToReturn;
}

+ (instancetype) new
{
   return [[SPFabric alloc] init];
}

- (instancetype) init
{
    self = [super init];
	
	if(self)
	{
		_registeredParameters = [NSMutableDictionary new];
		_producingTable = [NSMutableDictionary new];
	}
	
    return self;
}

- (id) produce:(Class _Nonnull)className
{
   return [self produce:className withParams:nil];
}

- (id) _doProducing:(Class)className
{
   return _producingTable[NSStringFromClass(className)](self);
}

- (id) produce:(Class _Nonnull)className withParams:(NSDictionary *_Nullable) params
{
     guard(!params) else
	 {
	 	defer(0, ^{
	    	self->_tmpParams = nil;
	 	});
	 	_tmpParams = params;
	 	return [self _doProducing:className];
	 }

     return [self _doProducing:className];
}

- (SomePromiseFuture*) produce:(Class _Nonnull)className onThread:(SomePromiseThread *_Nullable) thread
{
   return [self produce:className withParams:nil onThread:thread];
}

- (SomePromiseFuture*) produce:(Class _Nonnull)className onQueue:(dispatch_queue_t _Nullable) queue
{
	return [self produce:className withParams:nil onQueue:queue];
}

- (SomePromiseFuture*) produce:(Class _Nonnull)className  withParams:(NSDictionary *_Nullable) params onThread:(SomePromiseThread *_Nullable) thread
{
    if(thread == nil)
    {
       id result = [self produce:className withParams:params];
	   SomePromiseFuture *future = [[SomePromiseFuture alloc] initWithClass:className];
	   [future resolveWithObject:result];
	   if(self.onProduced)
	   {
	   		self.onProduced(result);
	   }
	   
	   return future;
	}
	else
	{
	
	   __weak SPFabric *weakSelf = self;
	   __block SomePromiseFuture *future = [[SomePromiseFuture alloc] initWithClass:className];
	   [thread performBlock:^
	   {
	        __strong SPFabric *strongSelf = weakSelf;
	        guard(strongSelf) else {return;}
			id result = [strongSelf produce:className withParams:params];
			[future resolveWithObject:result];
			if(strongSelf.onProduced)
	   		{
	   			strongSelf.onProduced(result);
	  		}
			
		}];
		
		return future;
	}
}

- (SomePromiseFuture*) produce:(Class _Nonnull)className withParams:(NSDictionary *_Nullable) params onQueue:(dispatch_queue_t _Nullable) queue
{
    if(queue == nil)
    {
		id result = [self produce:className withParams:params];
		SomePromiseFuture *future = [[SomePromiseFuture alloc] initWithClass:className];
		[future resolveWithObject:result];
		if(self.onProduced)
		{
			self.onProduced(result);
		}
		
	   return future;
	}
	else
	{
	   __block SomePromiseFuture *future = [[SomePromiseFuture alloc] initWithClass:className];
	   dispatch_async(queue, ^{
			id result = [self produce:className withParams:params];
			if(self.onProduced)
			{
				self.onProduced(result);
			}

			[future resolveWithObject:result];
		});
		
		return future;
	}
}

- (instancetype) register:(Class _Nonnull)className producingBlock:(ProducingBlock _Nonnull)block
{
   _producingTable[NSStringFromClass(className)] = [block copy];
   return self;
}

- (instancetype) registerParameters:(NSDictionary *_Nullable)params
{
   guard(params) else {[_registeredParameters removeAllObjects]; return self;}
   [_registeredParameters addEntriesFromDictionary:params];
   return self;
}

- (id _Nonnull (^ __nonnull)(Class _Nonnull className))produce
{
	__weak SPFabric *weakSelf = self;
	id (^block)(Class) = ^id (Class _Nonnull className)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf produce:className];
	};

	return [block copy];
}

- (id _Nonnull (^ __nonnull)(Class _Nonnull className, NSDictionary *_Nullable params))produceWithParams
{
	__weak SPFabric *weakSelf = self;
	id (^block)(Class, NSDictionary*) = ^id (Class _Nonnull className, NSDictionary *params)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf produce:className withParams:params];
	};

	return [block copy];
}


- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, SomePromiseThread *_Nullable thread))produceOnThread
{
	__weak SPFabric *weakSelf = self;
	SomePromiseFuture *(^block)(Class, SomePromiseThread*) = ^SomePromiseFuture *(Class _Nonnull className, SomePromiseThread *thread)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf produce:className onThread:thread];
	};

	return [block copy];
}

- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, dispatch_queue_t _Nullable queue))produceOnQueue
{
	__weak SPFabric *weakSelf = self;
	SomePromiseFuture *(^block)(Class, dispatch_queue_t) = ^SomePromiseFuture *(Class _Nonnull className, dispatch_queue_t queue)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf produce:className onQueue:queue];
	};

	return [block copy];
}

- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, SomePromiseThread *_Nullable thread, NSDictionary *_Nullable params))produceOnThreadWithParams
{
	__weak SPFabric *weakSelf = self;
	SomePromiseFuture *(^block)(Class, SomePromiseThread*, NSDictionary*) = ^SomePromiseFuture *(Class _Nonnull className, SomePromiseThread *thread, NSDictionary *params)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf produce:className withParams:params onThread:thread];
	};

	return [block copy];
}

- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, dispatch_queue_t _Nullable queue, NSDictionary *_Nullable params))produceOnThreadWithQueue
{
	__weak SPFabric *weakSelf = self;
	SomePromiseFuture *(^block)(Class, dispatch_queue_t, NSDictionary*) = ^SomePromiseFuture *(Class _Nonnull className, dispatch_queue_t queue, NSDictionary *params)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf produce:className withParams:params onQueue:queue];
	};

	return [block copy];
}

- (SPFabric *_Nonnull (^ __nonnull)(Class _Nonnull className, ProducingBlock _Nonnull producingBlock))registerClass
{
	__weak SPFabric *weakSelf = self;
	id (^block)(Class, ProducingBlock) = ^id (Class _Nonnull className, ProducingBlock producingBlock)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf register:className producingBlock:producingBlock];
	};

	return [block copy];
}

- (SPFabric *_Nonnull (^ __nonnull)(NSDictionary *_Nullable params))registerParameters
{
	__weak SPFabric *weakSelf = self;
	id (^block)(NSDictionary *) = ^id (NSDictionary *params)
	{
		__strong SPFabric *strongSelf = weakSelf;
		return [strongSelf registerParameters:params];
	};

	return [block copy];
}

@end

