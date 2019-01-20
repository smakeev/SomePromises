//
//  SomePromiseGenerator.h
//  SomePromises
//
//  Created by Sergey Makeev on 18/12/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol SPGeneratorYielder;
typedef id (^GeneratorBlock)(id<SPGeneratorYielder>, NSArray * _Nullable params);

@interface SPGeneratorResult : NSObject

@property (nonatomic, nullable, strong, readonly) id value;
@property (nonatomic, assign, readonly) BOOL done;

@end

@class SPGenerator;
@interface SPGeneratorBuilder : NSObject

+ (instancetype) createBuilderWithGenerator:(GeneratorBlock) generator; //generator block with id<SPGeneratorYielder> as first parametr. Could return any Object. return Void if nothing
- (SPGenerator*) build:( NSArray* _Nullable) params;

@end


@interface SPGeneratorResultProvider : NSObject
@property (nonatomic, nullable, readwrite) id value;
@end

@protocol SPGeneratorYielder <NSObject>
- (SPGeneratorResultProvider*) yield:(id) whatToReturn;
@end

@interface SPGenerator : NSObject <NSFastEnumeration>


- (SPGeneratorResult*)next;
- (SPGeneratorResult*)next:(id _Nullable)value;
- (NSEnumerator*)objectEnumerator;
@end

NS_ASSUME_NONNULL_END
