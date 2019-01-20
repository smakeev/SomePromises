//
//  EventsTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 21/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "EventsTestViewController.h"
#import "SomePromise.h"

@interface TestEventsClass : NSObject
{
   SomePromiseThread *_thread;
   NSTimer *_timer;
}
@end

@implementation TestEventsClass

- (instancetype) init
{
   self = [super init];
	
   if(self){
      _thread = [SomePromiseThread threadWithName:@"TestEventThread"];
	  __weak TestEventsClass *weakSelf = self;
      _timer = [_thread scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer *timer) {
          static int number = 0;
		  __strong TestEventsClass *strongSelf = weakSelf;
		  guard(strongSelf) else {return;}
		  strongSelf.spTrigger(@"testEvent", nil);
		  number += 5;
		  if (number > 25)
		  {
		     number = 0;
		     strongSelf.spTrigger(@"test1Event", nil);
		  }
      }];
   }
	
   return self;
}

- (void) dealloc
{
   NSLog(@"Deallocated deep");
   [_timer invalidate];
}

@end
//////
@interface KeyExample : NSObject
@end

@implementation KeyExample

- (void) dealloc
{
   NSLog(@"Key deallocated");
}

@end

@interface ValueExample : NSObject
@end

@implementation ValueExample
- (void) dealloc
{
   NSLog(@"Value deallocated");
}
@end


//////

@interface EventsTestViewController ()
{
   TestEventsClass *_mainTestInstance;
   __weak IBOutlet UIButton *button;
   SPMapTable<KeyExample*, ValueExample*> *table;
   SPMapTable<NSString*, NSString*> *table1;
}
@end

@implementation EventsTestViewController

- (IBAction)destroyWatcherPressed:(id)sender
{
	KeyExample *key1 = [[KeyExample alloc] init];
	
	key1.spOn(@"SomeExistingEvent", self, ^(NSDictionary *msg){
	   NSLog(@"SomeExistingEvent came");
	});
	
	key1.spTrigger(@"SomeExistingEvent", nil);
	
	key1.spDestroyListener(nil, ^(NSDictionary *msg){
	   NSLog(@"First on destroy block, no message: %@", msg);
	});
	
	key1.spDestroyListener(nil, ^(NSDictionary *msg){
	   NSLog(@"Second on destroy block, no message: %@", msg);
	});

	key1.spDestroyListener(nil, ^(NSDictionary *msg){
	   NSLog(@"Third on destroy block, no message: %@", msg);
	});

	key1.spDestroyListener(@{@"message1": @"value1"}, ^(NSDictionary *msg){
	   NSLog(@"First on destroy block, with message: %@", msg);
	});
	
	key1.spDestroyListener(@{@"message2": @"value2"}, ^(NSDictionary *msg){
	   NSLog(@"Second on destroy block, with message: %@", msg);
	});

	key1.spDestroyListener(@{@"message3": @"value3"}, ^(NSDictionary *msg){
	   NSLog(@"Third on destroy block, with message: %@", msg);
	});
}

- (IBAction)eventExpectorPressed:(id)sender
{
    [SPEventExpector waitForEvent:@"testEvent" fromTarget:_mainTestInstance ForTimeInterval:2.0 accept:nil onReceived:^(NSDictionary *msg) {
		NSLog(@"Expected an event for 2 seconds");
	} onTimeout:^{
		NSLog(@"2 seconds not enough");
	} waitOnThread:nil];
	
	__block SPEventExpector *expector = [SPEventExpector waitForEvent:@"test1Event" fromTarget:_mainTestInstance ForTimeInterval:0 accept:nil onReceived:^(NSDictionary *msg) {
		NSLog(@"Expected a long event");
	} onTimeout:^{
		NSLog(@"ERROR: Should Never execute");
	} waitOnThread:nil];
	
	[NSTimer scheduledTimerWithTimeInterval:10.0 repeats:NO block:^(NSTimer *timer) {
		if(expector.isActive)
		{
		  [expector reject];
		  NSLog(@"expector for long event rejected");
		}
		else
		{
		  NSLog(@"expector for long event is not active any more.");
		}
	}];
}

- (IBAction)waitPressed:(id)sender
{
	_mainTestInstance.waitForEvent(@"testEvent", self, ^(NSDictionary *msg) {
	   NSLog(@"Wait for event:");
	});
}

- (IBAction)pressed:(id)sender
{
   if([button.titleLabel.text isEqualToString:@"Subscribe"])
   {
	   [button  setTitle:@"Unsubscribe" forState:UIControlStateNormal];
	   [self subscribe];
   }
   else
   {
       [button  setTitle:@"Subscribe" forState:UIControlStateNormal];
       [self unsubscribe];
   }
}

- (void) subscribe
{
	_mainTestInstance.spOn(@"testEvent", self, ^(NSDictionary *msg){
	   NSLog(@"On: Periodic event got");
	});

   _mainTestInstance.spOnOnQueue(@"testEvent", dispatch_get_main_queue(), self, ^(NSDictionary *msg){
	   NSLog(@"OnOnMainQueue: Periodic event got");
	});

	_mainTestInstance.spOnce(@"testEvent", self, ^(NSDictionary *msg){
	    NSLog(@"Once: !!!! Periodic event got");
	});

	_mainTestInstance.spOnceOnQueue(@"testEvent",  dispatch_get_main_queue(), self, ^(NSDictionary *msg){
	    NSLog(@"Once: !!!! Periodic event got on main");
	});

}

- (void) unsubscribe
{
	_mainTestInstance.spOff(@"testEvent", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_mainTestInstance = [[TestEventsClass alloc] init];

//KeyExample *key1 = [[KeyExample alloc] init];
//ValueExample *value1 = [[ValueExample alloc] init];
//KeyExample *key2 = [[KeyExample alloc] init];
//ValueExample *value2 = [[ValueExample alloc] init];
//KeyExample *key3 = [[KeyExample alloc] init];
//ValueExample *value3 = [[ValueExample alloc] init];
//KeyExample *key4 = [[KeyExample alloc] init];
//ValueExample *value4 = [[ValueExample alloc] init];
//
//table = [SPMapTable new];
//NSLog(@"!!!!: %lu", (unsigned long)table.count);
//[table setObject:value1 forKey:key1];
//[table setObject:value2 forKey:key2];
//[table setObject:value3 forKey:key3];
//[table setObject:value4 forKey:key4];
//NSLog(@"!!!!: %lu", (unsigned long)table.count);
//value1 = nil;
//value2 = nil;
//value3 = nil;
//value4 = nil;
//key4 = nil;
//NSLog(@"!!!!: %lu", (unsigned long)table.count);
//[table removeObjectForKey:key2];
//NSLog(@"!!!!: %lu", (unsigned long)table.count);
//
//NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!");
//[table removeAllObjects];
//NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!");
//NSLog(@"!!!!: %lu", (unsigned long)table.count);
//
//table1 = [SPMapTable new];
//
//[table1 setObject:@"Object1" forKey:@"key1"];
//[table1 setObject:@"Object2" forKey:@"key2"];
//[table1 setObject:@"Object3" forKey:@"key3"];
//[table1 setObject:@"Object4" forKey:@"key4"];
//[table1 setObject:@"Object5" forKey:@"key5"];
//[table1 setObject:@"Object6" forKey:@"key6"];
//[table1 setObject:@"Object7" forKey:@"key7"];
//[table1 setObject:@"Object8" forKey:@"key8"];
//[table1 setObject:@"Object9" forKey:@"key9"];
//[table1 setObject:@"Object10" forKey:@"key10"];
//NSLog(@"!!!!: %lu", (unsigned long)table1.count);
//
//NSString *object1 = [table1 objectForKey:@"key1"];
//NSString *object2 = [table1 objectForKey:@"key2"];
//NSString *object3 = [table1 objectForKey:@"key3"];
//NSString *object4 = [table1 objectForKey:@"key4"];
//NSString *object5 = [table1 objectForKey:@"key5"];
//NSString *object6 = [table1 objectForKey:@"key6"];
//NSString *object7 = [table1 objectForKey:@"key7"];
//NSString *object8 = [table1 objectForKey:@"key8"];
//NSString *object9 = [table1 objectForKey:@"key9"];
//NSString *object10 = [table1 objectForKey:@"key10"];
//
//NSLog(@"%@, %@, %@, %@, %@, %@, %@, %@, %@, %@", object1, object2, object3, object4, object5, object6, object7, object8, object9, object10);
//
//NSEnumerator *enumerator = [table1 keyEnumerator];
//NSString *currentObject = nil;
//while ((currentObject = enumerator.nextObject))
//{
//    NSLog(@"%@ : %@",currentObject, [table1 objectForKey:currentObject]);
//}
//
}

- (void) dealloc
{
  NSLog(@"Deallocated");
  _mainTestInstance = nil;
}

@end
