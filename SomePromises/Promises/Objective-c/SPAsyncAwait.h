//
//  SPAsyncAwait.h
//  SomePromises
//
//  Created by Sergey Makeev on 25/12/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//
#import <Foundation/Foundation.h>
#define spasync SP_ASYNC:(BOOL)sp_async_await

#define SP_ASYNC_BEGIN { BOOL sp_async_await = YES; \
dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\

#define SP_ASYNC_END });}

#define SP_ASYNC(whatToCall) \
{\
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\
		[whatToCall SP_ASYNC:YES];\
	});\
}

#define SP_SYNC(whatToCall) \
{\
	dispatch_sync(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\
		[whatToCall SP_ASYNC:NO];\
	});\
}


#define SP_FUTURE(whatToCall) \
^\
{\
	SomePromiseFuture *future = [[SomePromiseFuture alloc] init]; \
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\
		id result = [whatToCall SP_ASYNC:YES];\
		[future resolveWithObject:result]; \
	});\
	return future; \
}()

#define SP_AWAIT_FUTURE(future) [((SomePromiseFuture*)future) get]

#define SP_AWAIT_PROMISE(promise) \
	^id () {\
		if (sp_async_await) {} \
		__block id _result = nil; \
		__block BOOL promiseFinished = NO;\
		NSCondition *condition = [[NSCondition alloc] init]; \
		promise.onSuccess(^(id result){ \
			_result = result;\
			promiseFinished = YES; \
			[condition signal]; \
		}).onReject(^(NSError *error){ \
			[condition signal]; \
			@throw error; \
		});\
		while (!promiseFinished) { \
			[condition wait]; \
		}\
		return _result; \
	}()\

#define SP_AWAIT(whatToCall) \
	^id () {\
		@try{ \
		id __result = SP_AWAIT_PROMISE([SomePromise promiseWithName:@"SP_AWAIT_PROMISE" \
                resolvers:^(StdBlocks) \
                {\
                	@try{ \
						id result = [whatToCall  SP_ASYNC: sp_async_await]; \
						fulfillBlock(result); \
					} \
					@catch(NSException *e) { \
						rejectBlock([SomePromiseUtils errorFromException:e]); \
					} \
					@catch(NSError *error) { \
						rejectBlock(error); \
					} \
				} \
                class:nil]); \
		return __result; \
		}\
		@catch (NSError *error) { \
			@throw error; \
		}\
	}()\

#define SP_AWAIT_WITHCOMPLETION(whatToCall, block) \
[SP_ASYNCAWAIT asyncWithCompletionBlock:^id{ \
			__block id result = nil; \
			NSCondition *condition = [[NSCondition alloc] init]; \
			__block BOOL blockFinished = NO; \
			[self testForAsyncFunctionWithCompletionBlock:^(NSString *str){ \
				block \
				blockFinished = YES; \
				[condition signal]; \
			}]; \
			while (!blockFinished) { \
				[condition wait]; \
			} \
			return result; \
		} SP_ASYNC:sp_async_await]; \

typedef id (^AsyncCallBlock)(void);

@interface SP_ASYNCAWAIT : NSObject
+ (id) asyncWithCompletionBlock:(AsyncCallBlock) callBlock spasync;
@end
