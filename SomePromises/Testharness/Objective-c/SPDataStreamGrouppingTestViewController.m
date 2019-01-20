//
//  SPDataStreamGrouppingTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 15/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SPDataStreamGrouppingTestViewController.h"
#import "SomePromise.h"

@interface TestSPArrayElement : NSObject

@property (nonatomic) NSNumber *number;

- (instancetype) initWithNumber:(NSNumber*)number;

@end

static TestSPArrayElement*  createTetedElement(NSNumber *number)
{
	return [[TestSPArrayElement alloc] initWithNumber:number];
}

@implementation TestSPArrayElement

- (instancetype) initWithNumber:(NSNumber*)number
{
	self = [super init];
	if(self)
	{
		self.number = number;
	}
	return self;
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"%ld", [self.number integerValue]];
}

@end

@interface SPDataStreamGrouppingTestViewController ()
{
	SomePromiseThread *thread1;
	SomePromiseThread *thread2;
	SomePromiseThread *thread3;
	SomePromiseThread *thread4;
	SomePromiseThread *thread5;
	SomePromiseThread *thread6;
	SomePromiseThread *thread7;
	SomePromiseThread *thread8;
	SomePromiseThread *thread9;
	SomePromiseThread *thread10;
	SomePromiseThread *threadFinal;
	
	__weak IBOutlet UILabel *glueTestLabel;
	__weak IBOutlet UIButton *startButton;
	
	__weak IBOutlet UITextField *textField1;
	
	__weak IBOutlet UITextField *textField2;
}
@end

@implementation SPDataStreamGrouppingTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    SPArray<TestSPArrayElement*> *array = [SPArray fromArray: @[createTetedElement(@(1)), createTetedElement(@(2)), @sp_weakly(createTetedElement(@(2)))]];
    NSLog(@"!! %ld", array.count);
        // Enumerate using a for loop and subscripted access.
        NSLog(@"Enumerating using a for loop...");
        for (NSUInteger i=0; i<array.count; i++)
        {
            NSLog(@"Item %li = %@", i, array[i].value.number);
        }

        // Enumerate using block-based enumeration.
        NSLog(@"Enumerating using block-based enumeration...");
        [array enumerateObjectsUsingBlock:^(TestSPArrayElement *obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"Item %li = %@", idx, obj.number);
        }];

        NSUInteger idx = 0;
	 
        // Enumerate using NSEnumerator.
        NSLog(@"Enumerating using NSEnumerator...");
        NSEnumerator *enumerator = [array objectEnumerator];
        SPArrayElementWrapper<TestSPArrayElement*> *currentObject;
        while ((currentObject = [enumerator nextObject]))
        {
            NSLog(@"Item %li = %@", idx++, currentObject.value.number);
        }
	 
        // Enumerate using fast enumeration.
        NSLog(@"Enumerating using fast enumeration...");
        idx = 0;
        for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
        {
            NSLog(@"Item %li = %@", idx++, item.value.number);
        }
	
        [array shrink];
	NSLog(@"!! %ld", array.count);
	
	TestSPArrayElement *el1 = (createTetedElement(@(1)));
	TestSPArrayElement *el2 = (createTetedElement(@(2)));
	TestSPArrayElement *el3 = (createTetedElement(@(3)));
	TestSPArrayElement *el4 = (createTetedElement(@(4)));
	TestSPArrayElement *el5 = (createTetedElement(@(5)));
	
	[array addWeakly:el1];
	[array addWeakly:el2];
	[array addWeakly:el3];
	[array addWeakly:el4];
	[array addWeakly:el5];
	NSLog(@"!! %ld", array.count);
	array.autoshrink = YES;
	el1 = nil;
	el2 = nil;
	el3 = nil;
	el4 = nil;
	el5 = nil;
	NSLog(@"!! Autoshrinking %ld", array.count);
	idx = 0;
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	
	[array appendArray:@[createTetedElement(@(10)), createTetedElement(@(11)), createTetedElement(@(12)), createTetedElement(@(13)), createTetedElement(@(14)), createTetedElement(@(15)), createTetedElement(@(16)), createTetedElement(@(17)), createTetedElement(@(18))]];
	NSLog(@"appended array");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	
	array[0] = createTetedElement(@(0));
	array[3] = createTetedElement(@(111));
	
	NSLog(@"change element at index 0");
	idx = 0;
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	
	[array add:createTetedElement(@(100))];
	
	el1 = createTetedElement(@(-1));
	el2 = createTetedElement(@(-2));
	el3 = createTetedElement(@(-3));
	el4 = createTetedElement(@(-4));
	el5 = createTetedElement(@(-5));
	
	[array pushForward:el1 weakly:YES];
	[array pushForward:el2 weakly:YES];
	[array pushForward:el3 weakly:YES];
	[array pushForward:el4 weakly:YES];
	[array pushForward:el5 weakly:YES];

	NSLog(@"add and push forward");
	idx = 0;
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	[array remove:el1];
	NSLog(@"removed -1");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	[array removeAtIndex:1];
	NSLog(@"removed -4 (index1)");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	[array appendArray:@[createTetedElement(@(101)), createTetedElement(@(102)), createTetedElement(@(103))]];
	NSLog(@"append array");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	
	[array insertArray:@[createTetedElement(@(104)), createTetedElement(@(105)), createTetedElement(@(106))] atIndex:3];
	NSLog(@"insert array at index 3");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Push array forward");
	[array pushArrayForward:@[createTetedElement(@(107)), createTetedElement(@(108)), createTetedElement(@(109))]];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	SPArray<TestSPArrayElement*> *arrayToAppend = [SPArray fromArray: @[createTetedElement(@(200)), createTetedElement(@(201)), @sp_weakly(createTetedElement(@(202)))]];
	[array appendSPArray:arrayToAppend];
	NSLog(@"append sparray");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"insert sparray at index");
	SPArray<TestSPArrayElement*> *arrayToInsert = [SPArray fromArray: @[createTetedElement(@(300)), createTetedElement(@(301)), @sp_weakly(createTetedElement(@(302)))]];
	[array insertSPArray:arrayToInsert atIndex:10];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"push sparray forward");
	SPArray<TestSPArrayElement*> *arrayToPush = [SPArray fromArray: @[createTetedElement(@(400)), createTetedElement(@(401)), @sp_weakly(createTetedElement(@(402)))]];
	[array pushSPArrayForward:arrayToPush];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"sort sparray");
	[array sortWithBlock:^(SPArrayElementWrapper<TestSPArrayElement*> *first, SPArrayElementWrapper<TestSPArrayElement*> *second){
		if([first.value.number integerValue] < [second.value.number integerValue])
			return NSOrderedAscending;
		if([first.value.number integerValue] > [second.value.number integerValue])
			return NSOrderedDescending;
		return NSOrderedSame;
	}];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Filter");
	[array filter:^BOOL(TestSPArrayElement*element){
		return [element.number integerValue] < 100;
	}];
	
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Filter wrapper");
	[array filterWrappers:^BOOL(SPArrayElementWrapper *wrapper) {
		return ![wrapper weakly];
	}];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Map");
	[array map:^id(TestSPArrayElement *object) {
		return  createTetedElement(@([object.number integerValue] * 100));
	}];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	[array reverse];
	NSLog(@"reverse");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	[array swap:0 with:9];
	NSLog(@"swap");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Shuffle");
	[array shuffle];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Flat. Should not be changes here");
	[array flat];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value.number);
	}
	idx = 0;
	NSLog(@"Complecated array");
	SPArray *arrayMain = [SPArray new];
    SPArray *array1 = [SPArray fromArray: @[createTetedElement(@(1)), createTetedElement(@(2)), createTetedElement(@(3))]];
    SPArray *array2 = [SPArray fromArray: @[createTetedElement(@(4)), createTetedElement(@(5)), createTetedElement(@(6))]];
    SPArray *array3 = [SPArray new];
    [array3 add:array2];
    [array3 add:createTetedElement(@(7))];
    [arrayMain add:array1];
	[arrayMain add:array3];
	[arrayMain add:createTetedElement(@(8))];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in arrayMain)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value);
	}
	idx = 0;
	NSLog(@"Flat of complecated array");
	[arrayMain flat];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in arrayMain)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value);
	}
	idx = 0;
	
	//
	NSLog(@"Reduce");
	float average = (float)[[array reduceResult:@(0) block:^id(id lastResult, NSUInteger startindex) {
		return @([lastResult integerValue] + [array[startindex].value.number integerValue]);
	}] integerValue] / (float)array.count;
	NSLog(@"%f", average);
	NSLog(@"Get by index");
	NSLog(@"%@",[array getByIndex:2]);
	NSLog(@"isElementWeaklyStoredAtIndex");
	NSLog(@"result: %d", [array isElementWeaklyStoredAtIndex:2]);
	NSLog(@"typeForIndex");
	NSLog(@"%@", [array typeForIndex:2]);
	NSLog(@"array");
	
	SPArray *arrayCopy = [array copy];
	[arrayCopy removeAtIndex:0];
	[arrayCopy removeAtIndex:1];
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value);
	}
	idx = 0;
	NSLog(@"copied and removed 0 and 1");
	for(SPArrayElementWrapper<TestSPArrayElement*>  *item in arrayCopy)
	{
		NSLog(@"Item %d %li = %@", item.weakly, idx++, item.value);
	}
	idx = 0;

	NSLog(@"has %d", [array has:el1]);
	NSLog(@"add el1");
	[array add:el1];
	NSLog(@"has %d", [array has:el1]);
	NSLog(@"is empty: %d", [array isEmpty]);
	NSLog(@"Enumerated");
	NSDictionary<NSNumber*, SPArrayElementWrapper<TestSPArrayElement*>*>* dictionary = [array enumerated];
	NSLog(@"Enumerated dict:%@", dictionary);
    NSLog(@"Random Element %@", [array randomElement]);
	NSLog(@"Random Element %@", [array randomElement]);
    NSLog(@"Random Element %@", [array randomElement]);
    NSLog(@"Random Element %@", [array randomElement]);

	NSLog(@"To Array: %@", [array toArray]);
	NSLog(@"To Array withwrappers: %@", [array toArrayWithWrappers]);

	NSLog(@"First: %@, Last: %@", [array first], [array last]);

	//multythreading test
	
	thread1 = [SomePromiseThread threadWithName:@"1st"];
	thread2 = [SomePromiseThread threadWithName:@"2nd"];
	thread3 = [SomePromiseThread threadWithName:@"3d"];
	thread4 = [SomePromiseThread threadWithName:@"4th"];
	thread5 = [SomePromiseThread threadWithName:@"5th"];
	thread6 = [SomePromiseThread threadWithName:@"6th"];
	thread7 = [SomePromiseThread threadWithName:@"7th"];
	thread8 = [SomePromiseThread threadWithName:@"8th"];
	thread9 = [SomePromiseThread threadWithName:@"9th"];
	thread10 = [SomePromiseThread threadWithName:@"10th"];
	
	threadFinal = [SomePromiseThread threadWithName:@"Final thread"];
	
	void(^finalBlock)(void) = ^{
		static int blockNumber = 0;
		blockNumber++;
		NSLog(@"block number:%d", blockNumber);
		if(blockNumber == 10)
		{
			NSLog(@"Final block:");
			NSUInteger idx = 0;
			for(SPArrayElementWrapper<TestSPArrayElement*>  *item in array)
			{
				NSLog(@"!!Final Item %d %li = %@", item.weakly, idx++, item.value);
			}
		} else if(blockNumber == 11)
		{
			blockNumber = 1;
		}
	};
	
	[thread1 performBlock:^{
			[array add:el1];
			[array add:el2];
			[array add:el3];
			[array add:el4];
			[self->threadFinal performBlock:finalBlock];
	}];
	[thread2 performBlock:^{
			[array remove:el1];
			[array remove:el2];
			[array remove:el3];
			[array remove:el4];
			[self->threadFinal performBlock:finalBlock];
	}];
	[thread3 performBlock:^{
			[array add:el1];
			[array add:el2];
			[array add:el3];
			[array add:el4];
			[array add:el5];
			[self->threadFinal performBlock:finalBlock];
	}];
	[thread4 performBlock:^{
			[array sortWithBlock:^(SPArrayElementWrapper<TestSPArrayElement*> *first, SPArrayElementWrapper<TestSPArrayElement*> *second){
					if([first.value.number integerValue] < [second.value.number integerValue])
						return NSOrderedAscending;
					if([first.value.number integerValue] > [second.value.number integerValue])
						return NSOrderedDescending;
					return NSOrderedSame;
				}];
			[self->threadFinal performBlock:finalBlock];
	}];
	[thread5 performBlock:^{
			[array reverse];
			[self->threadFinal performBlock:finalBlock];
	}];
	
	[thread6 performBlock:^{
				[array sortWithBlock:^(SPArrayElementWrapper<TestSPArrayElement*> *first, SPArrayElementWrapper<TestSPArrayElement*> *second){
					if([first.value.number integerValue] < [second.value.number integerValue])
						return NSOrderedAscending;
					if([first.value.number integerValue] > [second.value.number integerValue])
						return NSOrderedDescending;
					return NSOrderedSame;
				}];
			[self->threadFinal performBlock:finalBlock];
	}];
	
	[thread7 performBlock:^{
			[array shuffle];
			[self->threadFinal performBlock:finalBlock];
	}];
	
	[thread8 performBlock:^{
			[array shuffle];
			[self->threadFinal performBlock:finalBlock];
	}];
	
	[thread9 performBlock:^{
			[array sortWithBlock:^(SPArrayElementWrapper<TestSPArrayElement*> *first, SPArrayElementWrapper<TestSPArrayElement*> *second){
					if([first.value.number integerValue] < [second.value.number integerValue])
						return NSOrderedAscending;
					if([first.value.number integerValue] > [second.value.number integerValue])
						return NSOrderedDescending;
					return NSOrderedSame;
				}];
			[self->threadFinal performBlock:finalBlock];
	}];
	
	[thread10 performBlock:^{
		[array forEach:^(TestSPArrayElement *object, NSUInteger index, BOOL *stop) {
			NSLog(@"foreach Item %@ %li = %@", object.number, index, object);
		}];
		[self->threadFinal performBlock:finalBlock];
	}];
	
	[self setupObserversUnionsTest];
}

- (void) setupObserversUnionsTest
{
	//1 merge test:
	//We have two text fields and button start.
	//Button is desabled by default.
	//It should be enabled only when texts in both text fields are the same, and not empty
	startButton.enabled = NO;
	@sp_avoidblockretain(self)
	@sp_startUI(sp_action(startButton, ^(NSNumber *enabled){
		@sp_strongify(self)
		guard(self) else return;
		self->startButton.enabled = [enabled boolValue];
	})) = 	[SPDataStream merge:@[@sp_observeTextField(textField1), @sp_observeTextField(textField2)] withMergeRule:^id(SPArray *results) {
							NSString *firstText = results[0].value;
							NSString *secondText = results[1].value;
							return @([firstText isEqualToString:secondText]);
			}].ignoreIncomingNil(YES);

	@sp_startUI(sp_action(startButton, ^(UIButton *button){
			@sp_strongify(self)
			guard(self) else return;
			NSLog(@"Text:%@", self->textField1.text);
	})) =  @sp_observeControl(startButton, UIControlEventTouchUpInside);
	@sp_avoidend(self)
	
	@sp_uibind(glueTestLabel, text) = [SPDataStream glue:@[@sp_observeTextField(textField1), @sp_observeTextField(textField2)]];
}

@end
