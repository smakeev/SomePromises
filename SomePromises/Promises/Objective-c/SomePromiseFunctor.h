//
//  SomePromiseFunctor.h
//  SomePromises
//
//  Created by Sergey Makeev on 28/11/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

#define spf_run(name) ((FunctorBlock)(name.go))
#define spf_runForced(name)((FunctorBlock)(name.goForced))

#define sp_autoclosure(blockType) (SPAutoclosure<blockType>*)

NS_ASSUME_NONNULL_BEGIN

typedef  id (^ FunctorBlock)(NSArray *params);
typedef id (^ AutoclosureBlock)(void);

@protocol SomePromiseFunctorProtocol <NSObject>

- (instancetype) initWithBlock:(FunctorBlock) block;

@property (nonatomic, copy) FunctorBlock functorBlock;
 - (id(^ __nonnull)(NSArray *params)) go; //should retern block
 - (id(^ __nonnull)(NSArray *params)) goForced;
@end

@interface SPBaseFunctor : NSObject <SomePromiseFunctorProtocol>
@end

@interface SPLazyFunctor : SPBaseFunctor <SomePromiseFunctorProtocol>
@end

@interface SPAutoclosure<__covariant T> : NSProxy
- (instancetype) initWithBlock:(AutoclosureBlock) block;
@property (nonatomic, copy) AutoclosureBlock functorBlock;
 - (id(^ __nonnull)(void)) go;
 - (id(^ __nonnull)(NSArray *params)) goForced;
@end
NS_ASSUME_NONNULL_END
