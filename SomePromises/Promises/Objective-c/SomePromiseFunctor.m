//
//  SomePromiseFunctor.m
//  SomePromises
//
//  Created by Sergey Makeev on 28/11/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseFunctor.h"

@implementation SPBaseFunctor
@synthesize functorBlock = _functorBlock;
- (instancetype) initWithBlock:(FunctorBlock) block
{
	self = [super init];
	if(self) {
		self.functorBlock = block;
	}
	return self;
}

 - (id(^ __nonnull)(NSArray *params)) go
 {
 	return _functorBlock;
 }

- (id(^ __nonnull)(NSArray *params)) goForced
 {
 	return self.go;
 }


@end

@interface SPLazyFunctor()
{
	__nullable id _value;
}

@end

@implementation SPLazyFunctor

 - (id(^ __nonnull)(NSArray *params)) go
{
	__weak SPLazyFunctor *weakSelf = self;
	FunctorBlock block = (FunctorBlock)^(NSArray *params) {
		__strong SPLazyFunctor *strongSelf = weakSelf;
		if(!strongSelf)
		{
			return (id)nil;
		}
		if(strongSelf->_value)
		{
			return strongSelf->_value;
		}
		strongSelf->_value = ((FunctorBlock)strongSelf.functorBlock)(params);
		return (id)strongSelf->_value;
	};
	return [block copy];
}

 - (id(^ __nonnull)(NSArray *params)) goForced
 {
 	_value = nil;
 	return self.go;
 }

@end
