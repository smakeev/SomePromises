//
//  SomePromiseSignal.m
//  SomePromises
//
//  Created by Sergey Makeev on 15/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseSignal.h"
#import "SomePromiseUtils.h"
#import "SomePromiseThread.h"

@interface SomePromiseSignal()

@property(nonatomic, copy) NSString *name;
@property(nonatomic) NSInteger tag;
@property(nonatomic) NSDictionary *message;
@property(nonatomic) id anythingElse;
@property(nonatomic) BOOL handled;

@end

@implementation SomePromiseSignal

- (instancetype) initWithName:(NSString*)name tag:(NSInteger)tag message:(NSDictionary*)message anythingElse:(id)anythingElse
{
     self = [super init];
	
     if(self)
     {
		 self.name = name;
		 self.tag = tag;
		 self.message = message;
		 self.anythingElse = anythingElse;
	 }
	
	 return self;
}

@end

static void __sp_sendSignal(SomePromiseSignal *signal, NSArray<id> *to, id from)
{
  //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (id object in to)
      {
         guard([object shouldHandleSignal:signal]) else {continue;}
         dispatch_queue_t queue = [to queueForHandlingSignal:signal from:from];
         SomePromiseThread *thread = nil;
         if (queue == nil)
		    thread = [to threadForHandlingSignal:signal from:from];
	  
		 if(thread)
	     {
		    [thread performBlockSynchroniously:^{
			     [object handleTheSignal:signal];
			}];
	     }
	     else if(queue)
	     {
	        dispatch_sync(queue, ^{
               [object handleTheSignal:signal];
			});
	     }
	     else
	     {
		    [object handleTheSignal:signal];
		 }
		 
		 guard(!signal.handled) else {return;}
       }
  //});
}

static void __sp_handleSignal(SomePromiseSignal *signal)
{
   signal.handled = YES;
}

@implementation NSProxy (SomePromiseSignal)

- (void) sendSignal:(SomePromiseSignal*)signal toObject:(NSArray<id>*)targets
{
    __sp_sendSignal(signal, targets, self);
}

- (SomePromiseThread*)threadForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender
{
   return nil;
}

- (dispatch_queue_t)queueForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender
{
   return nil;
}

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{
   return NO;
}

- (void)handleTheSignal:(SomePromiseSignal*)signal
{
   __sp_handleSignal(signal);
}

@end

@implementation NSObject (SomePromiseSignal)

- (void) sendSignal:(SomePromiseSignal*)signal toObject:(NSArray<id>*)targets
{
    __sp_sendSignal(signal, targets, self);
}

- (SomePromiseThread*)threadForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender
{
   return nil;
}

- (dispatch_queue_t)queueForHandlingSignal:(SomePromiseSignal*)signal from:(id)sender
{
   return nil;
}

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{
   return NO;
}

- (void)handleTheSignal:(SomePromiseSignal*)signal
{
   __sp_handleSignal(signal);
}

@end
