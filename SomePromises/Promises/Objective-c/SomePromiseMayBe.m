//
//  SomePromiseMayBe.m
//  SomePromises
//
//  Created by Sergey Makeev on 28/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseMayBe.h"
#import "SomePromiseUtils.h"

@interface SPNil : NSObject
@end

@implementation SPNil
@end

@interface SPNone : SomePromiseMayBeCreator <SPMaybe>
@end

@implementation SPNone

- (Class) type
{
	return [SPNil class];
}

- (id)get
{
	FATAL_ERROR(@"unexpected nil", @"Maybe get returned nil while it must has a value. Try getOrElse if nil is possible here.")
	return nil;
}

- (id)getOrElse:(id)defaultValue
{
	return defaultValue;
}

- (BOOL)isNone
{
	return YES;
}

- (BOOL)isSome
{
	return NO;
}

- (SPMaybe *_Nonnull)noNil:(id)insteadNilValue
{
	return [SomePromiseMayBeCreator some:insteadNilValue];
}

- (void) unwrapWithBlock:(void(^)(id value))block
{
	//do nothing
}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block else:(void(^)(void))elseBlock
{
	elseBlock();
}

- (id) unwrap
{
	return nil;
}

- (BOOL) isWeak {
	return NO;
}

@end

@interface SomePromiseMayBeCreator ()

@property (nonatomic) Class providedType;

@end

@interface SPSome : SomePromiseMayBeCreator <SPMaybe>
{
	id _value;
	__weak id _weakValue;
}
@end

@implementation SPSome

- (Class) type
{
	if(self.providedType)
		return self.providedType;
	if (_value)
		return [_value class];
	return [_weakValue class];
}

- (instancetype) initWithValue:(id)value
{
	self = [super init];
	if(self)
	{
		_value = value;
	}
	return self;
}

- (instancetype) initWithWeakValue:(id)value
{
	self = [super init];
	if(self)
	{
		_weakValue = value;
	}
	return self;

}

- (id)get
{
	return _value ? : _weakValue;
}

- (id)getOrElse:(id)defaultValue
{
	return _value ? : _weakValue;
}

- (BOOL)isNone
{
	return _value ? NO : _weakValue ? NO : YES;
}

- (BOOL)isSome
{
	return ![self isNone];
}

- (SPMaybe *_Nonnull)noNil:(id)insteadNilValue
{
	if(_value || _weakValue)
		return self;
	return @sp_maybe(insteadNilValue);
}

- (void) unwrapWithBlock:(void(^)(id value))block
{
	if(_value)
		block(_value);
	else if (_weakValue) {
		block(_weakValue);
	}
}

- (id) unwrap
{
	return _value ? : _weakValue ? : nil;
}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block else:(void(^)(void))elseBlock
{
	if(_value) {
		block(_value);
	} else if (_weakValue) {
		block(_weakValue);
	}
	else {
		elseBlock();
	}
}

- (BOOL) isWeak {
	return _weakValue ? YES : NO;
}

@end

@implementation SomePromiseMayBeCreator

@dynamic type;

+ (id<SPMaybe>)some:(id)value withType:(Class)type
{
	SPMaybe *maybeToBeReturned = [SPMaybe some:value];
	maybeToBeReturned.providedType = type;
	return maybeToBeReturned;
}

+ (id<SPMaybe>)some:(id)value
{
	guard (value) else {return [SomePromiseMayBeCreator none];}
	return [[SPSome alloc] initWithValue:value];
}

+ (id<SPMaybe>)some:(id)value weak:(BOOL) weak
{
	guard (value) else {return [SomePromiseMayBeCreator none];}
	return [[SPSome alloc] initWithWeakValue:value];
}

+ (id<SPMaybe>)none
{
	static dispatch_once_t onceToken;
	static SPNone *none = nil;
	dispatch_once(&onceToken, ^{
		none = [[SPNone alloc] init];
	});

	return none;
}

+ (id<SPMaybe>)noNil:(id)value
{
	if(value)
	{
		return [SomePromiseMayBeCreator some:value];
	}
	return [SomePromiseMayBeCreator none];
}

+ (SPMaybe *_Nonnull)noNil:(id _Nullable)value weak:(BOOL) weak {
	if(value)
	{
		return [SomePromiseMayBeCreator some:value weak: weak];
	}
	return [SomePromiseMayBeCreator none];
}

+ (SPMaybe *_Nonnull)as:(id)valueToCast if:(Class) type
{
	guard([valueToCast isKindOfClass:type]) else {return [SPMaybe none];}
	return [SPMaybe some:valueToCast withType:type];
}


+ (id)as:(id)valueToCast sure:(Class) type
{
	guard([valueToCast isKindOfClass:type]) else {FATAL_ERROR(@"casting error", @"asSure can't cast type")}
	return valueToCast;
}

+ (void) unwrapSPMaybeGroup:(NSArray<SPMaybe>*)group withBlock:(void(^)(NSArray *values)) block else:(void(^)(void))elseBlock
{
	NSMutableArray *values = [NSMutableArray new];
	for(SPMaybe *maybe in group)
	{
		if([maybe isNone])
		{
			elseBlock();
			return;
		}
		else
		{
			[values addObject:maybe.unwrap];
		}
	}
	
	block([values copy]);
}

- (void) map:(void(^)(id value)) mapBlock {
	if(![self isNone])
	{
		mapBlock(self.unwrap);
	}
}
- (SPMaybe*) flatMap:(SPMaybe*(^)(id value)) mapBlock
{
	if(![self isNone])
	{
		SPMaybe *result = mapBlock(self.unwrap);
		return result;
	}
	else
	{
		return @sp_maybe(nil);
	}
}

- (void (^ __nonnull)(void (^ _Nonnull)(id)))map
{
	__weak SPMaybe *weakSelf = self;
	return [^void(void(^block)(id))
	{
		__strong SPMaybe *strongSelf = weakSelf;
		return [strongSelf map:block];
	} copy];
}

- (SPMaybe* (^ __nonnull)(SPMaybe* (^ _Nonnull)(id)))flatMap
{
	__weak SPMaybe *weakSelf = self;
	return [^SPMaybe*(SPMaybe*(^block)(id))
	{
		__strong SPMaybe *strongSelf = weakSelf;
		return [strongSelf flatMap:block];
	} copy];
}


- (BOOL) isNone {[self doesNotRecognizeSelector:_cmd]; return NO;}

- (BOOL) isSome {[self doesNotRecognizeSelector:_cmd]; return NO;}

- (id _Nonnull) get {[self doesNotRecognizeSelector:_cmd]; return self;}

- (id _Nullable) unwrap {[self doesNotRecognizeSelector:_cmd]; return nil;}

- (id _Nonnull) getOrElse:(id _Nonnull)defaultValue {[self doesNotRecognizeSelector:_cmd]; return self;}

- (SPMaybe *_Nonnull)noNil:(id _Nonnull)insteadNilValue {[self doesNotRecognizeSelector:_cmd]; return self;}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block {[self doesNotRecognizeSelector:_cmd];}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block else:(void(^)(void))elseBlock {[self doesNotRecognizeSelector:_cmd];}

- (BOOL)isWeak {
	[self doesNotRecognizeSelector:_cmd]; return NO;
}


@end
