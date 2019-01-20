//
//  SomePromise+SomePromise_Helper.m
//  SomePromises
//
//  Created by Sergey Makeev on 17/06/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromise.h"
BLOCK_SIGNATURE_AVAILABLE

hPromise hPromise_create(id creationBlock)
{
   return [creationBlock copy];
}

SomePromise* spTry(id creationBlock, ...)
{
 // creationBlock = [creationBlock copy];
  SomePromiseMutableSettings *settings = [[SomePromiseMutableSettings alloc] init];
  settings.status = ESomePromiseNonActive;
  settings.name = @"SomePromise default name";
  settings.resolvers = [[SomePromiseSettingsResolvers alloc] init];
  settings.worker = [[SomePromiseSettingsPromiseWorker alloc] init];
  settings.worker.queue = dispatch_queue_create("SomePromisesDefaultQueue", DISPATCH_QUEUE_CONCURRENT);
  NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
  const NSUInteger nargs = blockSignature.numberOfArguments - 1;
  const char rtype = blockSignature.methodReturnType[0];
	
  //parsing arguments
  va_list args;
  va_start(args, creationBlock);
  va_list args1;
  va_start(args1, creationBlock);
  NSInvocation *blockInvocation = [NSInvocation invocationForBlock:creationBlock withParameters:args1];
  va_end(args1);
  for(NSUInteger i = 0; i < nargs ; ++i)
  {
      const char* argType = [blockSignature getArgumentTypeAtIndex:i + 1];
      if (strcmp(argType, @encode(Class)) == 0 )
      {
		 settings.futureClass = va_arg(args, Class);
      } else if (argType[0] == '@')
      {
		  id arg = va_arg(args, id);
		  if([arg isKindOfClass:[NSString class]])
		  {
		      settings.name = (NSString*) arg;
		  } else if([arg isKindOfClass:[SomePromiseThread class]])
		  {
		      settings.worker = [[SomePromiseSettingsPromiseWorker alloc] init];
		      settings.worker.thread = arg;
		  } else if([arg isKindOfClass:[SomePromiseSettingsPromiseWorker class]])
		  {
		      settings.worker = arg;
		  } else if([arg isKindOfClass:[SomePromiseSettingsPromiseDelegateWorker class]])
		  {
		      settings.delegateWorker = arg;
		  }  else if([arg isKindOfClass:[SomePromiseDelegateWrapper class]])
		  {
		      settings.delegate = arg;
		  }  else if([arg conformsToProtocol:@protocol(SomePromiseDelegate)])
		  {
			  settings.delegate = [[SomePromiseDelegateWrapper alloc] init];
			  settings.delegate.delegate = arg;
		  } else if([arg isKindOfClass:[SomePromiseSettingsObserverWrapper class]])
		  {
		      settings.observers = arg;
		  } else if([arg isKindOfClass:[SomeProgressBlockProvider class]])
		  {
			  settings.progressBlockProvider = arg;
		  } else if([arg isKindOfClass:[SomeIsRejectedBlockProvider class]])
		  {
			  settings.isRejectedBlockProvider = arg;
		  }
		  else if([arg isKindOfClass:[SomeParameterProvider class]])
		  {
			 //Parameter is provided to be used in block.
			 // But we need to store it inside the settings
			 //Just not allow them be deleted before invoke.
			 if(!settings.parameters)
			 {
			 	settings.parameters = [NSMutableArray new];
			 }
			 [settings.parameters addObject:arg];
		  } else if([arg isKindOfClass:([NSObject<OS_dispatch_queue> class])]) //this should be last
		  {
		      settings.worker = [[SomePromiseSettingsPromiseWorker alloc] init];
		      settings.worker.queue = arg;
		  }
	  }
	  else
	  {
		    FATAL_ERROR(@"wrong parameter", @"Promise block does not support one or more of it's parameters")
	  }
  }
	
  __weak SomePromiseMutableSettings *weakSettings = settings;
  settings.resolvers.initBlock = ^(StdBlocks){
      @try{
        if(weakSettings && weakSettings.isRejectedBlockProvider)
        {
           weakSettings.isRejectedBlockProvider.isRejectedBlock = isRejectedBlock;
		}
		
		if(weakSettings && weakSettings.progressBlockProvider)
		{
		   weakSettings.progressBlockProvider.progressBlock = progressBlock;
		}
		
		[blockInvocation invoke];
	  }
      @catch(NSException *exception){
		   rejectBlock([SomePromiseUtils errorFromException:exception]);
		   return;
	  }
	  @catch(NSError *error){
		  rejectBlock(error);
		  return;
	  }
	  @catch(...){
		  rejectBlock(rejectionErrorWithText(@"Unknown Exception", ESomePromiseError_FromException));
		  return;
	  }
      switch (rtype)
      {
           case 'v':
                fulfillBlock(Void);
                return;
		   case '@':
		   {
			    __weak id block_result = nil;
			    [blockInvocation getReturnValue:&block_result];
			    if (!block_result || [block_result isKindOfClass:[NSError class]])
			    {
			        rejectBlock(block_result);
			        return;
				}
				fulfillBlock(block_result);
				return;
		   }
		   default:
		   {
			   id block_result = nil;
			   if(strcmp(&rtype, @encode(double)) == 0 ||  rtype == 'd')
			   {
			      double result = 0.0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithDouble:result];
			   }
               else if(strcmp(&rtype, @encode(float)) == 0 || rtype == 'f')
               {
				  float result = 0.0f;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithFloat:result];
			   }
               else if(strcmp(&rtype, @encode(unsigned long)) == 0 || rtype == 'Q')
               {
				  unsigned long result = 0.0f;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithUnsignedLong:result];
			   }
			   else if(strcmp(&rtype, @encode(unsigned long long)) == 0)
			   {
				  unsigned long long result = 0.0f;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithUnsignedLongLong:result];
			   }
			   else if(strcmp(&rtype, @encode(long)) == 0 || rtype == 'q')
			   {
				  long result = 0.0f;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithLong:result];
			   }
			   else if(strcmp(&rtype, @encode(long long)) == 0)
			   {
				  long long result = 0.0f;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithLongLong:result];
			   }
			   else if(strcmp(&rtype, @encode(int)) == 0  || rtype == 'i')
			   {
				  int result = 0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithInt:result];
			   }
			   else if(strcmp(&rtype, @encode(unsigned int)) == 0 || rtype == 'I')
			   {
				  unsigned int result = 0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithUnsignedInt:result];
			   }
			   else if(strcmp(&rtype, @encode(BOOL)) == 0 || strcmp(&rtype, @encode(bool)) == 0 || rtype == 'B')
			   {
				  BOOL result = NO;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithBool:result];
			   }
			   else if(strcmp(&rtype, @encode(char)) == 0 || rtype == 'c')
			   {
				  char result = 0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithChar:result];
			   }
			   else if(strcmp(&rtype, @encode(unsigned char)) == 0 || rtype == 'C')
			   {
				  unsigned char result = 0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithUnsignedChar:result];
			   }
			   else if(strcmp(&rtype, @encode(short)) == 0 || rtype == 's')
               {
				  short result = 0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithShort:result];
			   }
			   else if(strcmp(&rtype, @encode(unsigned short)) == 0 || rtype == 'S')
               {
				  unsigned short result = 0;
				  [blockInvocation getReturnValue:&result];
				  block_result = [NSNumber numberWithUnsignedShort:result];
			   }
			   else if (rtype == 'r' ||
			            rtype == '*' ||
			            rtype == '^' ||
			            strcmp(&rtype, @encode(char *)) == 0 ||
			            rtype == '?' ) //pointer ( and const pointer)
			   {
				   void *result = NULL;
				   [blockInvocation getReturnValue:&result];
				   if(result == NULL)
				   {
				      rejectBlock(nil);
				      return;
				   }
				   block_result = [NSValue valueWithPointer:result];
			   }
			   else
			   {
			       FATAL_ERROR(@"unsupported return type", @"Promise block's return type is unsupported.")
			   }
			   fulfillBlock(block_result);
		   }
      }
  };
  va_end(args);
  guard ([settings consistent]) else {return nil;}
  return [SomePromise promiseWithSettings:settings];
}

@implementation SomePromise (SomePromise_Helper)
- (id _Nullable) get
{
    return self.getFuture.get;
}
@end
