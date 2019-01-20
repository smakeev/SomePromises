//
//  SPAsyncAwait.m
//  SomePromises
//
//  Created by Sergey Makeev on 28/12/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SPAsyncAwait.h"

@implementation SP_ASYNCAWAIT
+ (id) asyncWithCompletionBlock:(AsyncCallBlock)  callBlock spasync {
	return callBlock();
}
@end
