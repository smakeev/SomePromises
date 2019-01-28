//
//  SPActor.h
//  SomePromises
//
//  Created by Sergey Makeev on 23/01/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

#define actor(name) interface name: SPActor

@class SomePromiseThread;
NS_ASSUME_NONNULL_BEGIN

@interface SPActor : NSObject
+ (instancetype) queueActor:(dispatch_queue_t) queue;
+ (instancetype) threadActor:(SomePromiseThread*)thread;
+ (instancetype) mainActor;
- (id) get:(NSString*) key;
@end

NS_ASSUME_NONNULL_END
