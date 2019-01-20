//
//  ExtendTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 20/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "ExtendTestViewController.h"
#import "SomePromise.h"

@interface ExtentionExample: NSObject
@end

@implementation ExtentionExample

- (void) dealloc
{
   NSLog(@"Extention deallocated");
}

@end


@interface ExtendTEstClass: NSObject
@end

@implementation ExtendTEstClass

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{
   return YES;
}

- (void)handleTheSignal:(SomePromiseSignal*)signal
{
    if([signal.name isEqualToString:@"ToAll"])
    {
        NSLog(@"SignalToAll, don't handle");
	}
	else
	{
	    [super handleTheSignal:signal];
	    NSLog(@"Signal:%@ handled", signal.name);
	}
}

- (void) dealloc
{
   NSLog(@"Extended deallocated");
}

@end

@interface ExtendTestViewController ()
@property (weak, nonatomic) IBOutlet UIButton *signalTest;
@property (weak, nonatomic) IBOutlet UIButton *extendTest;

@end

@implementation ExtendTestViewController

- (IBAction)testPressed:(id)sender {

    ExtendTEstClass *testInstance = [[ExtendTEstClass alloc] init];
    ExtendTEstClass *testInstance1 = [[ExtendTEstClass alloc] init];
        ExtendTEstClass *testInstance2 = [[ExtendTEstClass alloc] init];
            ExtendTEstClass *testInstance3 = [[ExtendTEstClass alloc] init];
                ExtendTEstClass *testInstance4 = [[ExtendTEstClass alloc] init];
                    ExtendTEstClass *testInstance5 = [[ExtendTEstClass alloc] init];
                        ExtendTEstClass *testInstance6 = [[ExtendTEstClass alloc] init];
                            ExtendTEstClass *testInstance7 = [[ExtendTEstClass alloc] init];
                                ExtendTEstClass *testInstance8 = [[ExtendTEstClass alloc] init];
                                   ExtendTEstClass *testInstance9 = [[ExtendTEstClass alloc] init];
  if(sender == self.signalTest)
  {
	   SomePromiseSignal *signal = [[SomePromiseSignal alloc] initWithName:@"ToAll" tag:0 message:nil anythingElse:nil];
	   SomePromiseSignal *signal1 = [[SomePromiseSignal alloc] initWithName:@"ToFirst" tag:0 message:nil anythingElse:nil];
	  [testInstance sendSignal:signal toObject:@[testInstance1, testInstance2, testInstance3, testInstance4, testInstance5, testInstance6, testInstance7, testInstance8, testInstance9]];
	  
	  [testInstance sendSignal:signal1 toObject:@[testInstance1, testInstance2, testInstance3, testInstance4, testInstance5, testInstance6, testInstance7, testInstance8, testInstance9]];
  }
  else
  {
	testInstance1.spExtend(@"testField", @(3), nil, nil);
	testInstance2.spExtend(@"testField", @(3), nil, nil);
	testInstance3.spExtend(@"testField", @(3), nil, nil);
	testInstance4.spExtend(@"testField", @(3), nil, nil);
	testInstance5.spExtend(@"testField", @(3), nil, nil);
	testInstance6.spExtend(@"testField", @(3), nil, nil);
	testInstance7.spExtend(@"testField", @(3), nil, nil);
	testInstance8.spExtend(@"testField", @(3), nil, nil);
	testInstance9.spExtend(@"testField", @(3), nil, nil);

	ExtentionExample *ex1 = [[ExtentionExample alloc] init];
    ExtentionExample *ex2 = [[ExtentionExample alloc] init];
    ExtentionExample *ex3 = [[ExtentionExample alloc] init];
    ExtentionExample *ex4 = [[ExtentionExample alloc] init];
    ExtentionExample *ex5 = [[ExtentionExample alloc] init];
    ExtentionExample *ex6 = [[ExtentionExample alloc] init];
    ExtentionExample *ex7 = [[ExtentionExample alloc] init];
    ExtentionExample *ex8 = [[ExtentionExample alloc] init];
    ExtentionExample *ex9 = [[ExtentionExample alloc] init];

	testInstance1.spExtend(@"testField", ex1, nil, nil);
	testInstance2.spExtend(@"testField", ex2, nil, nil);
	testInstance3.spExtend(@"testField", ex3, nil, nil);
	testInstance4.spExtend(@"testField", ex4, nil, nil);
	testInstance5.spExtend(@"testField", ex5, nil, nil);
	testInstance6.spExtend(@"testField", ex6, nil, nil);
	testInstance7.spExtend(@"testField", ex7, nil, nil);
	testInstance8.spExtend(@"testField", ex8, nil, nil);
	testInstance9.spExtend(@"testField", ex9, nil, nil);

	NSLog(@"!!testField %d expected:(0)", testInstance.spHas(@"testField"));
    testInstance.spExtend(@"testField", @(3), nil, nil);
	NSLog(@"!!testField %d expected:(1)", testInstance.spHas(@"testField"));
    NSLog(@"!!testField value:%@ expected:(3)", testInstance.spGet(@"testField"));
	testInstance.spSet(@"testField", @(5));
	NSLog(@"!!testField value:%@ expected:(5)", testInstance.spGet(@"testField"));
	testInstance.spUnset(@"testField");
	NSLog(@"!!testField %d expected:(0)", testInstance.spHas(@"testField"));
	
	testInstance.spExtend(@"testField", @(1), ^(SPValueProvider *currentValueProvider, id newValue){
	   NSLog(@"testField Custom setter (+5 to provided value)");
	   currentValueProvider.value = @([newValue integerValue] + 5);
	}, ^(id value){
	   NSLog(@"testField custom getter");
	   return value;
	});
	NSLog(@"!!testField %d expected:(1)", testInstance.spHas(@"testField"));
	NSLog(@"!!testField value:%@ expected:(1)", testInstance.spGet(@"testField"));
	testInstance.spSet(@"testField", @(5));
	NSLog(@"!!testField value:%@ expected:10", testInstance.spGet(@"testField"));
   //---------

	NSLog(@"!!testField1 %d expected:(0)", testInstance.spHas(@"testField1"));
    testInstance.spExtend(@"testField1", @(3), nil, nil);
	NSLog(@"!!testField1 %d expected:(1)", testInstance.spHas(@"testField1"));
    NSLog(@"!!testField1 value:%@ expected:(3)", testInstance.spGet(@"testField1"));
	testInstance.spSet(@"testField1", @(5));
	NSLog(@"!!testField1 value:%@ expected:(5)", testInstance.spGet(@"testField1"));
	testInstance.spUnset(@"testField1");
	NSLog(@"!!testField1 %d expected:(0)", testInstance.spHas(@"testField1"));
	
	testInstance.spExtend(@"testField1", @(1), ^(SPValueProvider *currentValueProvider, id newValue){
	   NSLog(@"testField1 Custom setter (+5 to provided value)");
	   currentValueProvider.value = @([newValue integerValue] + 5);
	}, ^(id value){
	   NSLog(@"testField1 custom getter");
	   return value;
	});
	NSLog(@"!!testField1 %d expected:(1)", testInstance.spHas(@"testField1"));
	NSLog(@"!!testField1 value:%@ expected:(1)", testInstance.spGet(@"testField1"));
	testInstance.spSet(@"testField1", @(5));
	NSLog(@"!!testField1 value:%@ expected:10", testInstance.spGet(@"testField1"));

   //two in sep threads
    testInstance1 = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

	         NSLog(@"!!testField2 %d expected:(0)", testInstance.spHas(@"testField2"));
             testInstance.spExtend(@"testField2", @(3), nil, nil);
	         NSLog(@"!!testField2 %d expected:(1)", testInstance.spHas(@"testField2"));
             NSLog(@"!!testField2 value:%@ expected:(3)", testInstance.spGet(@"testField2"));
			 testInstance.spSet(@"testField2", @(5));
	         NSLog(@"!!testField2 value:%@ expected:(5)", testInstance.spGet(@"testField2"));
	         testInstance.spUnset(@"testField2");
	         NSLog(@"!!testField2 %d expected:(0)", testInstance.spHas(@"testField2"));
	
	         testInstance.spExtend(@"testField2", @(1), ^(SPValueProvider *currentValueProvider, id newValue){
	              NSLog(@"testField2 Custom setter (+5 to provided value)");
	              currentValueProvider.value = @([newValue integerValue] + 5);
			 }, ^(id value){
	           NSLog(@"testField2 custom getter");
	           return value;
	         });
	      //   sleep(10);
	         NSLog(@"!!testField2 %d expected:(1)", testInstance.spHas(@"testField2"));
	         NSLog(@"!!testField2 value:%@ expected:(1)", testInstance.spGet(@"testField2"));
	         testInstance.spSet(@"testField2", @(5));
	         NSLog(@"!!testField2 value:%@ expected:10", testInstance.spGet(@"testField2"));
	});
    testInstance2 = nil;
    testInstance3 = nil;
    testInstance4 = nil;
    testInstance5 = nil;
   //---------

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // sleep(10);
	     NSLog(@"!!testField3 %d expected:(0)", testInstance.spHas(@"testField3"));
         testInstance.spExtend(@"testField3", @(3), nil, nil);
	     NSLog(@"!!testField3 %d expected:(1)", testInstance.spHas(@"testField3"));
         NSLog(@"!!testField3 value:%@ expected:(3)", testInstance.spGet(@"testField3"));
	     testInstance.spSet(@"testField3", @(5));
	     NSLog(@"!!testField3 value:%@ expected:(5)", testInstance.spGet(@"testField3"));
	     testInstance.spUnset(@"testField3");
	     NSLog(@"!!testField3 %d expected:(0)", testInstance.spHas(@"testField3"));
	
	     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			  ExtendTEstClass *testSubInstance = [[ExtendTEstClass alloc] init];
			  testSubInstance.spExtend(@"testField", @(3), nil, nil);
		      NSLog(@"!!testField value:%@ expected:(3)", testSubInstance.spGet(@"testField"));
	     });
	
	
	     testInstance.spExtend(@"testField3", @(1), ^(SPValueProvider *currentValueProvider, id newValue){
		       NSLog(@"testField3 Custom setter (+5 to provided value)");
	           currentValueProvider.value = @([newValue integerValue] + 5);
	     }, ^(id value){
	        NSLog(@"testField3 custom getter");
	        return value;
	     });
	     NSLog(@"!!testField3 %d expected:(1)", testInstance.spHas(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     NSLog(@"!!testField3 value:%@ expected:(1)", testInstance.spGet(@"testField3"));
	     testInstance.spSet(@"testField3", @(5));
	     NSLog(@"!!testField3 value:%@ expected:10", testInstance.spGet(@"testField3"));
		
	     NSLog(@"!!---CUSTOM EXTEND-------");
		
	});
  }

}



@end
