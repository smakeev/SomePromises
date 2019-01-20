//
//  HelperTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 18/06/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "HelperTestViewController.h"
#import "SomePromise.h"

@interface HelperTestViewController () <SomePromiseDelegate, SomePromiseObserver>
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation HelperTestViewController

- (void) promise:(SomePromise*_Nonnull) promise gotResult:(id _Nonnull ) result
{
     NSLog(@"Promise: %@ finished with result: %@", promise.name, result);
}

- (void) promise:(SomePromise*_Nonnull) promise rejectedWithError:(NSError*_Nullable) error
{
      NSLog(@"Promise: %@ rejected with error", promise.name);
}

- (void) promise:(SomePromise*_Nonnull) promise stateChangedFrom:(PromiseStatus) oldStatus to:(PromiseStatus) newStatus
{
	NSLog(@"Promise: %@ status was %lu current status is: %lu", promise.name, (unsigned long)oldStatus, (unsigned long)newStatus);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
/*
    //0) simple (no parameters)
	//0 a 1 return and success
	spTry(^{
		   return;
	}).onSuccess(^(id result){
	   NSLog(@"P0 success :%@", result);
	});
	//0 a 2 return and reject
	spTry(^{
		   return rejectionErrorWithText(@"test error", 2);
	}).onReject(^(NSError *error){
	   NSLog(@"P0 rejected :%@", error);
	});
	//0 b return NSString
	spTry(^{
		   return @"Test String as a result";
	}).onSuccess(^(id result){
	   NSLog(@"P0 success :%@", result);
	});
    //	//0 c return int
	spTry(^{
		   return 3;
	}).onSuccess(^(id result){
	   NSLog(@"P0 success :%@", result);
	});
	//0  2 return and reject by exception
	spTry(^{
	      NSException *e = [NSException
                                  exceptionWithName:@"ExampleException"
                                             reason:@"Example of an exception"
                                           userInfo:nil];
		   @throw e;
		   return;
	}).onReject(^(NSError *error){
	   NSLog(@"P0 rejected by exception :%@", error);
	});
	//----------------------------------------------
	//1) simple (1 parameter, name)
	//1 a 1 return and success
	spTry(^(NSString *name){
		   return;
	}, @"Test_Name").onSuccess(^(id result){
	   NSLog(@"P1 success :%@", result);
	});
	//1 a 2 return and reject
	spTry(^(NSString *name){
		   return rejectionErrorWithText(@"test error", 2);
	}, @"Test_Name").onReject(^(NSError *error){
	   NSLog(@"P1 rejected :%@", error);
	});
	//1 b return NSString
	spTry(^(NSString *name){
		   return @"Test String as a result";
	}, @"Test_Name").onSuccess(^(id result){
	   NSLog(@"P1 success :%@", result);
	});
    //1 c return int
	spTry(^(NSString *name){
		   return 3;
	}, @"Test_Name").onSuccess(^(id result){
	   NSLog(@"P1 success :%@", result);
	});
	//1  2 return and reject by exception
	spTry(^(NSString *name){
	      NSException *e = [NSException
                                  exceptionWithName:@"ExampleException"
                                             reason:@"Example of an exception"
                                           userInfo:nil];
		   @throw e;
		   return;
	}, @"Test_Name").onReject(^(NSError *error){
	   NSLog(@"P1 rejected by exception :%@", error);
	});
	//----------------------------------------------------------------------
	//2) simple (2 parameterы, name, class)
	//2 a 1 return and success
	spTry(^(NSString *name, Class class){
		   return;
	}, @"Test_Name", [Void class]).onSuccess(^(id result){
	   NSLog(@"P2 success :%@", result);
	});
	//2 a 2 return and reject
	spTry(^(NSString *name, Class class){
		   return rejectionErrorWithText(@"test error", 2);
	}, @"Test_Name", [NSObject class]).onReject(^(NSError *error){
	   NSLog(@"P3 rejected :%@", error);
	});
	//2 b return NSString
	spTry(^(NSString *name, Class class){
		   return @"Test String as a result";
	}, @"Test_Name", [NSString class]).onSuccess(^(id result){
	   NSLog(@"P2 success :%@", result);
	});
    //2 c return int
	spTry(^(NSString *name, Class class){
		   return 3;
	}, @"Test_Name", [NSNumber class]).onSuccess(^(id result){
	   NSLog(@"P2 success :%@", result);
	});
	//2  2 return and reject by exception
	spTry(^(NSString *name, Class class){
	      NSException *e = [NSException
                                  exceptionWithName:@"ExampleException"
                                             reason:@"Example of an exception"
                                           userInfo:nil];
		   @throw e;
		   return;
	}, @"Test_Name", [NSObject class]).onReject(^(NSError *error){
	   NSLog(@"P2 rejected by exception :%@", error);
	});
	//2  2 return and reject by thrown error
		spTry(^(NSString *name, Class class){
	       
		   @throw rejectionErrorWithText(@"test_error", 1001);
		   return;
	}, @"Test_Name", [NSObject class]).onReject(^(NSError *error){
	   NSLog(@"P2 rejected by exception :%@", error);
	});
*/

//Threads and queues
//	spTry(^(dispatch_queue_t queue)
//	{
//		   return 3;
//	}, dispatch_get_main_queue());
//
//	spTry(^(SomePromiseThread *thread)
//	{
//		   return 3;
//	}, [SomePromiseThread threadWithName:@"Test thread"]);

//	spTry(^(PromiseWorker worker)
//	{
//		   return 3;
//	}, promiseWorkerWithName(@"Test worker thread"));


//////////////////////////////////////////////
//delegateWorker
//	spTry(^(DelegateWorker worker)
//	{
//		   return 3;
//	}, delegateWorkerWithName(@"Test worker thread"));

//delegate

//	spTry(^(id<SomePromiseDelegate> delegate)
//	{
//		   return 3;
//	}, self);
	
////////////////////////////////////////////////

//delegate and worker
//	spTry(^(id<SomePromiseDelegate> delegate, DelegateWorker worker)
//	{
//		   return 3;
//	}, self, delegateWorkerWithName(@"Test worker thread"));

//observers.
//   SomePromiseSettingsObserverWrapper *wrapper = [[SomePromiseSettingsObserverWrapper alloc] init];
//   [wrapper addObserver:self onThread:[SomePromiseThread threadWithName:@"TEST THREAD"]];
//
//	spTry(^(SomePromiseSettingsObserverWrapper *observers)
//	{
//		   return 3;
//	}, wrapper);

//progress and isRejected

//id result = spTry(^(SomeIsRejectedBlockProvider *isRejected, SomeProgressBlockProvider *progress){
//
//  for (int i = 0; i < 100; ++i)
//  {
//     if(isRejected.isRejectedBlock())
//     {
//        return 0;
//	 }
//	 else
//	 {
//	    sleep(1);
//	    progress.progressBlock(i);
//	 }
//  }
//
//  return 3;
//  }, isRejectedProvider(), progressProvider()).onProgress(^(float progress){NSLog(@"Progress: %f", progress);}).onSuccess(^(id result){ NSLog(@"Success: %@", result);}).onReject(^(NSError *error){ NSLog(@"Rejected");}).get;
//
//  NSLog(@"!!! Result: %@", result);
//

//   SomePromiseSettingsObserverWrapper *wrapper = [[SomePromiseSettingsObserverWrapper alloc] init];
//   [wrapper addObserver:self onThread:[SomePromiseThread threadWithName:@"TEST THREAD"]];
//
//   spTry(^
//   {
//      return 3;
//   })
//   .spNext(^(NSString *name, SomePromiseSettingsObserverWrapper *wrapper, id<SomePromiseDelegate> delegate, SomeResultProvider *resultProvider)
//   {
//     sleep(5);
//     long result = [resultProvider.result integerValue];
//     return result + 5;
//   }, @"spNextTry", wrapper, self, resultProvider())
//      .onSuccess(^(id result)
//      {
//         NSLog(@"!!! result: %@", result);
//
//	  })
//      .onReject(^(NSError *error)
//      {
//	      NSLog(@"Rejected");
//      }
//   );
	
//   SomePromiseSettingsObserverWrapper *wrapper = [[SomePromiseSettingsObserverWrapper alloc] init];
//   [wrapper addObserver:self onThread:[SomePromiseThread threadWithName:@"TEST THREAD"]];
//
//   spTry(^
//   {
//      return 3;
//   })
//   .spNext(^{return nil;})
//   .spThen(^(NSString *name, SomePromiseSettingsObserverWrapper *wrapper, id<SomePromiseDelegate> delegate, SomeResultProvider *resultProvider, dispatch_queue_t queue)
//   {
//     sleep(5);
//     long result = [resultProvider.result integerValue];
//     return result + 5;
//   }, @"spThenTry", wrapper, self, resultProvider(), dispatch_get_main_queue())
//      .onSuccess(^(id result)
//      {
//         NSLog(@"!!! result: %@", result);
//	  })
//      .onReject(^(NSError *error)
//      {
//	      NSLog(@"spThenTry Rejected");
//      }
//   )
//   .spElse(^(NSString *name, SomeValuesInChainProvider *provider)
//   {
//	  return [provider.chain.lastResultInChain integerValue] + 10;
//   }, @"elsePromise", valuesProvider()
//   ).onSuccess(^(id result)
//      {
//         NSLog(@"!!! result: %@", result);
//	  });
//
//RESULT_CONDITION(result.integerValue == 3)
//	  spTry(^{
//	     return 3;
//	  }).spWhere(RESULT_CONDITION([result integerValue] == 3), ^
//	  {
//	      NSLog(@"BLOCK::");
//	      return 5;
//	  }).onSuccess(^(id result){
//	      NSLog(@"!! %@", result);
//	  }).onReject(^(NSError *error){
//	      NSLog(@"Э %@", error);
//	  }).spAfterTime(10, ^(NSString *name, SomeResultProvider *result){
//	     NSLog(@"After Time: %@", result.result);
//	  }, @"After Time Example", resultProvider());

	  NSObject *object = [NSObject new];
	  NSObject *object2 = self;
      SomePromise *promiseToWaitFor = spTry(^{
		  //sleep(10);
		 // NSLog(@"!!! Finished self %@ ", self);
		  //NSLog(@"!!! Finished object %@ ", object);
		  //NSLog(@"!!! Finished object_self %@", object2);
	  });

	  id ws = self;
	  spTry(^{
	  	 //sleep(2);
	  	// NSLog(@"%@", self);
	     return 3;
	  }).spWhere(RESULT_CONDITION([result integerValue] == 3), ^
	  {
		  NSLog(@"!!! Finished self %@ ", self);
		  NSLog(@"!!! Finished object %@ ", object);
		  NSLog(@"!!! Finished object_self %@", object2);
	      NSLog(@"BLOCK::");
	      return 5;
	  }).onSuccess(^(id result){
	      NSLog(@"!! %@", result);
	  }).onReject(^(NSError *error){
	      NSLog(@"Э %@", error);
	  }).spIf(CONDITION(3 == 4), ^
	  {
		NSLog(@"NEVER");
	  }).onReject(^(NSError *error){
	      NSLog(@"spIf rejected %@", error);
	  }).spCatch(ERROR_CONDITION(error.code == 6), ^
	  {
		  //do nothing. Should have Void in success
	  }).onSuccess(^(id result){
	      NSLog(@"cp catch!! %@", result);
	  }).spAfter(@[promiseToWaitFor], ^(NSString *name, SomeResultProvider *result){
	     NSLog(@"After Promise: %@", result.result);
	  }, @"After Promise Example", resultProvider())
	  .spWhen(^(ResultParams){
	     fulfillBlock(@(2));
	  }, ^(NSString *name){
	     for (int i = 0; i < 10; ++i)
	     {
			NSLog(@"When %d", i);
			sleep(1);
		 }
		 return Void;
	  }, @"WhenPromise").onSuccess(^(id result){
	     NSLog(@"Success LAST result: %@", result);
	     dispatch_async(dispatch_get_main_queue(), ^{
			self.label.text = @"Finished";
         });
	  });
}

@end
