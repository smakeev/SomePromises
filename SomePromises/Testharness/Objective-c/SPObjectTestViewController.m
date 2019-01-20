//
//  SPObjectTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 25/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SPObjectTestViewController.h"
#import "SomePromise.h"
#import <objc/runtime.h>

@protocol ObjectTestProtocol1 <NSObject>
@optional
- (void) testProtocolMethod;

@end

@protocol ObjectTestProtocol2 <NSObject>

- (void) test2ProtocolMethod;

@end

@interface ObjectTestClass : NSObject <ObjectTestProtocol1>

@property (nonatomic, strong)ObjectTestClass *next;

- (void) testMethod;
- (void) test1Method:(NSString*)str;
- (void) test2Method:(NSUInteger)index;
- (void) test3Method:(NSUInteger)index test:(NSNumber*)number;
- (NSString*) test4;
- (NSUInteger) test5;

@end

@implementation ObjectTestClass

- (void) methodForSuperTest
{
	NSLog(@"MethodForSuperTest");
}

- (void) dealloc
{
	NSLog(@"Dealloc !!!!!!");
}

- (instancetype)initWithValue:(int) value string:(NSString*)string
{
	self = [super init];
	if(self)
	{
		NSLog(@"Original init with parameters:%@, %d", string, value);
	}
	return self;
}

- (instancetype)init
{
	NSLog(@"Original init");
	return [super init];
}

- (void) testMethod
{
	NSLog(@"Origial");
}

- (void) test1Method:(NSString*)str
{
	NSLog(@"Origial %@", str);
}

- (void) test2Method:(NSUInteger)index
{
	NSLog(@"Origial %lu", (unsigned long)index);
}

- (void) test3Method:(NSUInteger)index test:(NSNumber*)number
{
	NSLog(@"Origial %lu, %lu", (unsigned long)index, [number integerValue]);
}

- (NSString*) test4
{
	NSLog(@"Origial test4");
	return @"Origial test4";
}

- (NSUInteger) test5
{
	NSLog(@"Origial test5");
	return 5;
}

@end

@interface SPObjectTestViewController ()
{
	ObjectTestClass *_testInstance;
	
	__weak IBOutlet UITableView *_table;
}
@end

@implementation SPObjectTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//////////////////
//tuple testing

    SPTuple *tuple = [SPTuple new:createTuple(5, @(0), @(1), @(2), @(3), @(4))];
	NSLog(@"elements in tuple: %ld", tuple.count);
	NSLog(@"element 0 in tuple: %@", [tuple valueAt:0]);
	NSLog(@"element 1 in tuple: %@", [tuple valueAt:1]);
	NSLog(@"element 2 in tuple: %@", [tuple valueAt:2]);
	NSLog(@"element 3 in tuple: %@", [tuple valueAt:3]);
	NSLog(@"element 4 in tuple: %@", [tuple valueAt:4]);
	
	NSLog(@"Values in tuple: %@", [tuple getValues]);
	NSLog(@"Names in tuple: %@)", [tuple names]);
	NSLog(@"Name for 1st: %@)", [tuple nameAt:0]);
	
	//named tuple
	
	SPTuple *namedTuple = [SPTuple new:createTuple(3, @sp_named(x, @(0.0)), @sp_named(y, @(3.0)), @sp_named(z, @(-8.0)))];
	NSLog(@"elements in tuple: %ld", namedTuple.count);
	NSLog(@"element 0 in tuple: %@", [namedTuple valueAt:0]);
	NSLog(@"element 1 in tuple: %@", [namedTuple valueAt:1]);
	NSLog(@"element 2 in tuple: %@", [namedTuple valueAt:2]);
	NSLog(@"element 3 in tuple: %@", [namedTuple valueAt:3]);
	NSLog(@"element 4 in tuple: %@", [namedTuple valueAt:4]);
	
	NSLog(@"Values in tuple: %@", [namedTuple getValues]);
	NSLog(@"Names in tuple: %@", [namedTuple names]);
	NSLog(@"Name for 1st: %@", [namedTuple nameAt:0]);
//////////////////
	ObjectTestClass *first = [[ObjectTestClass alloc] init];
	ObjectTestClass *second = nil;

	SPMaybe *maybeF = @sp_maybe(first);
	SPMaybe *maybeS = @sp_maybe(second);
///	ObjectTestClass *unwrappedFirst
	[maybeF unwrapWithBlock:^(ObjectTestClass *value) {
		NSLog(@"First unwrapped");
	}];

	[maybeS unwrapWithBlock:^(ObjectTestClass *value) {
		NSLog(@"Second unwrapped");
	} else:^{
		NSLog(@"Second is nil");
	}];
	// sfIf
	SPMaybe *casted = @asMaybe(first, [ObjectTestClass class]);
	SPMaybe *casted2 =  @asMaybe(second, [ObjectTestClass class]);
	
	[SPMaybe unwrapSPMaybeGroup:@[casted, casted2] withBlock:^(NSArray *values) {
		//Should not be here
		NSLog(@"!!! error in SomeMaybeCasting");
	} else:^{
		NSLog(@"Casting checked");
	}];
	
	NSObject *newRefToFirst = @asSure(first, [NSObject class]);
	NSLog(@"%@ asSure", newRefToFirst);
	//
	@sp_iflet(ObjectTestClass *value, maybeF)
		NSLog(@"First unwrapped %@", value);
	@sp_iflet_end
	
	@sp_iflet(ObjectTestClass *value, maybeS)
		NSLog(@"!!Second unwrapped %@", value);
	sp_else
		NSLog(@"!!Second is nil %@", maybeS);
	@sp_iflet_end
	
/////////////////
	
	_testInstance = (ObjectTestClass*)[SomePromiseObject createObjectBasedOn:[ObjectTestClass class]
																   protocols:@[@protocol(ObjectTestProtocol1), @protocol(ObjectTestProtocol2)]
															  bindLifetimeTo:nil
															      definition:^(SomePromiseObject* creator) {
																	  [creator override:@selector(testMethod) with:^(id self){
																		  	NSLog(@"From Object");
																	  }];
																	  
																	  [creator override:@selector(test1Method:) with:^(id self, NSString *str){
																		  NSLog(@"From Object %@", str);
																	  }];
																	  
																	  [creator override:@selector(test2Method:) with:^(id self, NSUInteger index){
																	  	NSLog(@"From Object %lu", (unsigned long)index);
																	  }];
																	  
																	  [creator override:@selector(test3Method:test:) with:^(id self, NSUInteger index, NSNumber *number){
																	  	NSLog(@"From Object %lu, %lu", (unsigned long)index, (unsigned long)[number integerValue]);
																	  }];
																	  
																	  [creator override:@selector(test4) with:^NSString*(id self){
																	  	NSLog(@"From Object test4");
																	  	return @"From Object test4";
																	  }];

																	  [creator override:@selector(test5) with:^NSUInteger(id self){
																	  	NSLog(@"From Object test5");
																	  	return 51;
																	  }];
																	  //protocol method
																	  
																	  [creator override:@selector(testProtocolMethod) with:^(id self){
																	  	NSLog(@"testProtocolMethod");
																	  }];
																	  
																	  [creator override:@selector(test2ProtocolMethod) with:^(id self){
																	  	NSLog(@"test2ProtocolMethod");
																	  }];
																  }];
	
//Dynamic Delegate Test

	_table.delegate = (NSObject<UITableViewDelegate>*)[SomePromiseObject createObjectBasedOn:[NSObject class]
																   protocols:@[@protocol(UITableViewDelegate)]
															  bindLifetimeTo:_table
															      definition:^(SomePromiseObject* creator) {
																	  
													  }];

	_table.dataSource = (NSObject<UITableViewDataSource>*)[SomePromiseObject createObjectBasedOn:[ObjectTestClass class]
																   protocols:@[@protocol(UITableViewDataSource)]
															  bindLifetimeTo:_table
															      definition:^(SomePromiseObject* creator) {
																	 
																	 	[creator addVar:@"_lines" initial:@(50)];
																	 
																	 	@sp_avoidblockretain(self)
																	 	[creator bindTo:@"_lines" handler:^(id result) {
																			dispatch_async(dispatch_get_main_queue(), ^{
																	 			@sp_strongify(self)
																	 			UITableView *table = self->_table;
																	 			if(table)
																					[table reloadData];
																			});
																		}];
																	 	@sp_avoidend(self)
																	  
																	 	[creator override:@selector(init) with:^id(NSObject *self){
																	
																	 	sp_voidCallSuper(self, @selector(methodForSuperTest));
																	 
																	 	////////////////////////////////////////////
																	 	//self = sp_callSuper(self, @selector(init));
																	 	IMP superImp = sp_superIMP(self, @selector(initWithValue:string:));
																	 	id(* foo)(id, SEL, int, NSString*) = (id (*)(__strong id, SEL, int, NSString*))superImp;
																	 	self = foo(self, @selector(initWithValue:string:), 56, @"test string");
																	 	///////////////////////////////////////////
																	 	if(self)
																	 	{
																			NSLog(@"Init called");
																	 	}
																	 	return self;
																	}];
																	 
																	 [creator override:@selector(tableView:numberOfRowsInSection:) with:^NSInteger(NSObject *self, UITableView *table, NSInteger section){
																		 return [self.spGet(@"_lines") integerValue];
																	  }];
																	  
																	[creator override:@selector(tableView:cellForRowAtIndexPath:) with:^UITableViewCell*(NSObject *self, UITableView *table, NSIndexPath *indexPath){
																		UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"testCell"];
																		if(cell == nil)
																		{
																			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:@"testCell"];
																		}
																		cell.textLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
																		return cell;
																	}];
																	
																	[creator addDealloc:^{
																		NSLog(@"First Dealloc");
																	}];
																	  
																	[creator addDealloc:^{
																		NSLog(@"Second Dealloc");
																	}];

																	[creator addDealloc:^{
																		NSLog(@"Third Dealloc");
																	}];
													  }];
}

- (IBAction)firstTest:(id)sender
{
	[_testInstance testMethod];
	[_testInstance test1Method:@"new string"];
	[_testInstance test2Method:5];
	[_testInstance test3Method:10 test:@(20)];
	NSLog(@"RESULT test4: %@", [_testInstance test4]);
	NSLog(@"RESULT test5: %lu", (unsigned long)[_testInstance test5]);
	//protocols
	[_testInstance testProtocolMethod];
	if ([_testInstance conformsToProtocol:@protocol(ObjectTestProtocol2)])
	{
		[((id<ObjectTestProtocol2>)_testInstance) test2ProtocolMethod];
	}
	
	NSLog(@"datasource:%@", _table.dataSource );
}

- (IBAction)testBind:(UIButton*)sender
{
	NSObject* object = (NSObject*)_table.dataSource;
	object.spSet(@"_lines", @(arc4random_uniform((u_int32_t )50)));
}


@end
