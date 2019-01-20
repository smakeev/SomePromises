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


@end

@interface SomePromiseMayBeCreator ()

@property (nonatomic) Class providedType;

@end

@interface SPSome : SomePromiseMayBeCreator <SPMaybe>
{
	id _value;
}
@end

@implementation SPSome

- (Class) type
{
	if(self.providedType)
		return self.providedType;
	return [_value class];
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

- (id)get
{
	return _value;
}

- (id)getOrElse:(id)defaultValue
{
	return _value;
}

- (BOOL)isNone
{
	return NO;
}

- (BOOL)isSome
{
	return YES;
}

- (SPMaybe *_Nonnull)noNil:(id)insteadNilValue
{
	return self;
}

- (void) unwrapWithBlock:(void(^)(id value))block
{
	block(_value);
}

- (id) unwrap
{
	return _value;
}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block else:(void(^)(void))elseBlock
{
	block(_value);
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

- (BOOL) isNone {[self doesNotRecognizeSelector:_cmd]; return NO;}

- (BOOL) isSome {[self doesNotRecognizeSelector:_cmd]; return NO;}

- (id _Nonnull) get {[self doesNotRecognizeSelector:_cmd]; return self;}

- (id _Nullable) unwrap {[self doesNotRecognizeSelector:_cmd]; return nil;}

- (id _Nonnull) getOrElse:(id _Nonnull)defaultValue {[self doesNotRecognizeSelector:_cmd]; return self;}

- (SPMaybe *_Nonnull)noNil:(id _Nonnull)insteadNilValue {[self doesNotRecognizeSelector:_cmd]; return self;}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block {[self doesNotRecognizeSelector:_cmd];}

- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block else:(void(^)(void))elseBlock {[self doesNotRecognizeSelector:_cmd];}

@end
