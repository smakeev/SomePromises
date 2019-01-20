//
//  GeneratorTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 18/12/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "GeneratorTestViewController.h"
#import "SomePromise.h"

@interface GeneratorTestViewController ()

@end

@implementation GeneratorTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // first test:
	SPGeneratorBuilder *builder = [SPGeneratorBuilder createBuilderWithGenerator: ^id(id<SPGeneratorYielder> yielder, NSArray *params) {
		[yielder yield:@(0)];
		[yielder yield:@(1)];
		[yielder yield:@(2)];
		[yielder yield:@(3)];
		return @(4);
	}];
	
	SPGenerator *generator1 = [builder build:nil];
	SPGeneratorResult *result = [generator1 next];
	NSLog(@"!! Genertor return: {%@, %d}", result.value, result.done);
	result = [generator1 next];
	NSLog(@"!! Genertor return: {%@, %d}", result.value, result.done);
	result = [generator1 next];
	NSLog(@"!! Genertor return: {%@, %d}", result.value, result.done);
	result = [generator1 next];
	NSLog(@"!! Genertor return: {%@, %d}", result.value, result.done);
	result = [generator1 next];
	NSLog(@"!! Genertor return: {%@, %d}", result.value, result.done);
	
	//one extra
	result = [generator1 next];
	NSLog(@"!! Genertor return: {%@, %d}", result.value, result.done);
	
	//second test. Check next with parameter
	SPGeneratorBuilder *builder2 = [SPGeneratorBuilder createBuilderWithGenerator: ^id(id<SPGeneratorYielder> yielder, NSArray *params) {
		SPGeneratorResultProvider *ask1 = [yielder yield:@"ask1: 2+2?"];
		NSLog(@"ASK1 answer!: %@", ask1.value);
		SPGeneratorResultProvider *ask2 = [yielder yield:@"ask2: 3+3?"];
		NSLog(@"ASK2 answer!: %@", ask2.value);
		return Void;
	}];
	
	SPGenerator *generator2 = [builder2 build:nil];
	NSLog(@"!!! %@", [generator2 next].value);
	NSLog(@"!!! %@", [generator2 next:@(4)].value);
	NSLog(@"!!! %d", [generator2 next:@(9)].done);
	
	//test for in
		SPGenerator *generator1_1 = [builder build:nil];
		for (NSNumber *number in generator1_1)
		{
			NSLog(@"from for: %@", number);
		}
	
	//test enumerator
	SPGenerator *generator1_2 = [builder build:nil];
	NSEnumerator *enumerator = generator1_2.objectEnumerator;
	NSLog(@"!!! %@", enumerator.nextObject);
	NSLog(@"!!! %@", enumerator.nextObject);
	NSLog(@"!!! %@", enumerator.nextObject);
	NSLog(@"!!! %@", enumerator.nextObject);
	NSLog(@"!!! %@", enumerator.nextObject);
	NSLog(@"!!! %@", enumerator.nextObject);
	NSLog(@"!!! %@", enumerator.nextObject);
	//test 3: nested generators
	SPGeneratorBuilder *builder3 = [SPGeneratorBuilder createBuilderWithGenerator: ^id(id<SPGeneratorYielder> yielder, NSArray<NSNumber*> *params) {
		for (long i = params[0].integerValue; i <= params[1].integerValue; ++i)
		{
			[yielder yield:@(i)];
		}
		return Void;
	}];
	SPGeneratorBuilder *builder4 = [SPGeneratorBuilder createBuilderWithGenerator: ^id(id<SPGeneratorYielder> yielder, NSArray *params) {
		[yielder yield:[builder3 build:@[@(48), @(57)]]];
		[yielder yield:[builder3 build:@[@(65), @(90)]]];
		[yielder yield:[builder3 build:@[@(97), @(122)]]];
		return Void;
	}];
	
	SPGenerator *generator3 = [builder4 build:nil];
	for (NSNumber *number in generator3)
	{
		NSLog(@"VALUE: %@", number);
	}
}



@end
