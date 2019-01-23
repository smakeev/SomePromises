//
//  TestFunctors.m
//  SomePromises
//
//  Created by Sergey Makeev on 28/11/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "TestFunctors.h"
#import "SomePromise.h"



@implementation TestFunctors

- (NSString*) asyncFunctionExample2:(NSString*) what spasync {

	sleep(2);
	return what;
}
- (NSString*) asyncFunctionExample:(NSString*) what spasync {

	sleep(5);
	return what;
}

- (NSString*) asyncFunctionResult:(NSString*) what what2:(NSString*) what2 spasync {

	NSString *res1 = SP_AWAIT(self asyncFunctionExample:what);
	NSString *res2 = SP_AWAIT(self asyncFunctionExample2:what2);

	return [NSString stringWithFormat:@"%@ : %@", res1, res2];
}

- (void) tryF {
	NSLog(@"TRYTRYTRY");
}

- (void) asyncString:(NSString*) what what2:(NSString*) what2 spasync {
	[self tryF];
	NSString *result = SP_AWAIT(self asyncFunctionResult:what what2:what2);
	NSLog(@"RSULT: %@", result);
}

//promise func in async call
- (SomePromise*) promiseToBeReturned
{
	return spTry(^{
		sleep(10);
		return @(100);
	});
}

typedef void (^TestCompletionBlock)(NSString* result);
- (void) testForAsyncFunctionWithCompletionBlock:(TestCompletionBlock) completionBlock {
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		sleep(10);
		completionBlock(@"good result");
	});
}

- (void) asyncPromise:(NSString*)str spasync {
	NSNumber *fromPromise = SP_AWAIT_PROMISE([self promiseToBeReturned]);
	NSLog(@"RESULT: %@", fromPromise);
}

//3 case async with future
- (NSString*) asyncFunc1:(NSString*) param1 spasync {
	sleep(3);
	return @"Func1 response";
}

- (NSString*) asyncFunc2:(NSString*) param2 spasync {
	sleep(5);
	return @"Func2 response";
}

- (NSString*) asyncFunc3From1:(NSString*) fromFirst fromSecond:(NSString*) fromSecond spasync {
	sleep(2);
	return [NSString stringWithFormat:@"RESULT: %@ + %@", fromFirst, fromSecond];
}

// asyncFunc1 and asyncFunc2 are independent functions and can work same time

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	SP_ASYNC(self asyncString:@"First" what2:@"Second");
	SP_ASYNC(self asyncPromise:@"fakeParam");
	SP_ASYNC_BEGIN
		NSString *result = SP_AWAIT_WITHCOMPLETION(self testForAsyncFunctionWithCompletionBlock:^(NSString *str), result = str;);
		NSLog(@"ASYNC AWAIT with completion block: %@", result);
	SP_ASYNC_END
	
	//3d case
	SP_ASYNC_BEGIN
		NSString *first = (NSString*)SP_FUTURE(self asyncFunc1:@"firstParam");
		NSString *second = (NSString*)SP_FUTURE(self asyncFunc2:@"secondParam");
		NSString *result = SP_AWAIT(self asyncFunc3From1:SP_AWAIT_FUTURE(first) fromSecond:SP_AWAIT_FUTURE(second));
		NSLog(@"ASYNC AWAIT with Future: %@", result);
	SP_ASYNC_END
	
	SPBaseFunctor *concatenator = [[SPBaseFunctor alloc] initWithBlock:^(NSArray *params) {
		return [NSString stringWithFormat:@"%@%@", params[0], params[1]];
	}];
	
	//NSLog(@"%@", ((FunctorBlock)(concatenator.go))(@"First+", @"Last"));
	NSLog(@"%@", spf_run(concatenator)(@[@"before+", @"Before"]));
	
	SPLazyFunctor *lazyConcatenator = [[SPLazyFunctor alloc] initWithBlock:^(NSArray *params) {
		return [NSString stringWithFormat:@"%@%@", params[0], params[1]];
	}];
	NSLog(@"%@", spf_run(lazyConcatenator)(@[@"lazyBefore+", @"LazyBefore"]));
	
	NSLog(@"%@", spf_run(concatenator)(@[@"after+", @"After"]));
	
	NSLog(@"%@", spf_run(lazyConcatenator)(@[@"lazyAfter+", @"LazyAfter"])); //Should print lazyBefore
	
	NSLog(@"%@", spf_runForced(lazyConcatenator)(@[@"lazyAfter+", @"LazyAfter"]));
}

@end
