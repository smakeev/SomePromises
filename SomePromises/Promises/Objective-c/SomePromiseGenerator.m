//
//  SomePromiseGenerator.m
//  SomePromises
//
//  Created by Sergey Makeev on 18/12/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseGenerator.h"

@interface __SPGeneratorEnumerator : NSEnumerator
{
	SPGenerator *_generator;
	NSUInteger _currentIndex;
}

- (instancetype) initWithGenerator:(SPGenerator*)generator;
@end

@implementation __SPGeneratorEnumerator

- (instancetype) initWithGenerator:(SPGenerator*)generator
{
	self = [super init];
	if(self)
	{
		_generator = generator;
	}
	return self;
}

- (id) nextObject
{
	return [_generator next];
}

@end

@interface SPGeneratorResult()
@property (nonatomic, nullable, strong, readwrite) id value;
@property (nonatomic, assign, readwrite) BOOL done;
@end

@implementation SPGeneratorResult

@synthesize value, done;

@end

@implementation SPGeneratorResultProvider
@end

@interface SPGenerator () <SPGeneratorYielder>
{
	NSCondition* _condition;
	NSCondition* _returnCondition;
	dispatch_queue_t _queue;
	__nullable id _lastResult;
	BOOL _done;
	SPGeneratorResultProvider *_lastResultProvider;
}

@property (atomic) BOOL returnConditionReady;
@property (atomic) BOOL yieldConditonReady;
@property (nonatomic, copy) NSArray *params;
@property (nonatomic, copy) GeneratorBlock generatorBlock;
@property (atomic) id lastResult;
@property (atomic) BOOL done;
@property (atomic) SPGeneratorResultProvider *lastResultProvider;

- (instancetype) initWithGenerator:(id) generator params:(NSArray*)params;

@end

@interface SPGeneratorBuilder()

@property (nonatomic, copy) GeneratorBlock generatorBlock;

@end

@implementation SPGeneratorBuilder
+ (instancetype) createBuilderWithGenerator:(GeneratorBlock) generator
{
	SPGeneratorBuilder *builder = [[SPGeneratorBuilder alloc] init];
	builder.generatorBlock = generator;
	return builder;
}

- (SPGenerator*) build:(NSArray*) params
{
	return [[SPGenerator alloc] initWithGenerator: self.generatorBlock params:params];
}
@end

@implementation SPGenerator
@synthesize lastResult = _lastResult;

- (instancetype) initWithGenerator:(id) generator params:(NSArray*)params
{
	self = [super init];
	if (self)
	{
		self.generatorBlock = generator;
		self.params = params;
	}
	return self;
}

- (NSEnumerator*)objectEnumerator
{
	return [[__SPGeneratorEnumerator alloc] initWithGenerator:self];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len
{
	NSUInteger count = 0;
	unsigned long countOfItemsAlreadyEnumerated = state->state;
	if(countOfItemsAlreadyEnumerated == 0)
	{
		state->mutationsPtr = &state->extra[0];
	}
	if(!self.done)
	{
		state->itemsPtr = buffer;
		while((!self.done) && count < len)
		{
			id element = [self next].value;
			if(self.done)
				break;
			buffer[count] = element;
			countOfItemsAlreadyEnumerated++;
			count++;
		}
	}
	else
	{
		count = 0;
	}
	
	state->state = countOfItemsAlreadyEnumerated;
	return count;
}

- (SPGeneratorResultProvider*) yield:(id) whatToReturn
{
	if([whatToReturn isKindOfClass:[SPGenerator class]])
	{
		SPGenerator *parentGenerator = (SPGenerator*)whatToReturn;
		for (id val in parentGenerator)
		{
				[self yield:val];
		}
		return self.lastResultProvider;
	}
	else
	{
		self.lastResult = whatToReturn;
	}
	self.returnConditionReady = YES;
	[self->_returnCondition signal];
	while(!self.yieldConditonReady)
	{
		[_condition wait];
	}
	self.yieldConditonReady = NO;
	return self.lastResultProvider;
}

- (SPGeneratorResult*)next
{
	return [self next:nil];
}

- (SPGeneratorResult*)next:(id _Nullable)value
{
	if (!self.lastResultProvider)
	{
		self.lastResultProvider = [[SPGeneratorResultProvider alloc] init];
	}
	self.lastResultProvider.value = value;
	
	if (_done)
	{
		SPGeneratorResult *result = [[SPGeneratorResult alloc] init];
		result.done = YES;
		result.value = self.lastResult;
		return result;
	}
	
	if (_condition == nil)
	{
		_condition = [[NSCondition alloc] init];
		_returnCondition = [[NSCondition alloc] init];
		_queue = dispatch_queue_create("generatorQueue", DISPATCH_QUEUE_SERIAL);
		dispatch_async(_queue, ^{
			self.lastResult = self.generatorBlock(self, self.params);
			self.done = YES;
			self.returnConditionReady = YES;
			[self->_returnCondition signal];
		});
	}
	else
	{
		self.yieldConditonReady = YES;
		[_condition signal];
	}
	while (!self.returnConditionReady)
	{
		[_returnCondition wait];
	}
	self.returnConditionReady = NO;
	SPGeneratorResult *result = [[SPGeneratorResult alloc] init];
	result.done = self.done;
	result.value = self.lastResult;
	return result;
}

@end
