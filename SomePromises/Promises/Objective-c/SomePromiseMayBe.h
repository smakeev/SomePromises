//
//  SomePromiseMayBe.h
//  SomePromises
//
//  Created by Sergey Makeev on 28/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

//SomePromiseMayBe is a container
//It could contain your object or nil.
//And can be uwrapped

//ex:
//	SPMaybe maybe = @sp_maybe(object);
//
//	@sp_iflet(ObjectClass *value, maybe)
//		NSLog(@"unwrapped %@", value);
//	sp_else
//		NSLog(@"maybe %@ is nil ", maybe);
//	@sp_iflet_end

@protocol SPMaybe;
@class SomePromiseMayBeCreator;
typedef SomePromiseMayBeCreator<SPMaybe> SPMaybe;

//returns maybe with value casted to type if isKindOf type or nil
#define asMaybe(ref, type) "should be called with @" @"". length ? [SPMaybe as:ref if:type] : nil

//returns value casted to type if isKind of a type or will crah
#define asSure(ref, type) "should be called with @" @"". length ? [SPMaybe as:ref sure:type] : nil

//create maybe based on provided instance or nil.
#define sp_maybe(val) "should be called with @" @"". length ? [SomePromiseMayBeCreator noNil:val] : nil
#define sp_weak_maybe(val) "should be called with @" @"". length ? [SomePromiseMayBeCreator noNil:val weak:YES] : nil
//unwrap maybe to value if maybe is not nil
//unwrapped value will be available inside the body
#define sp_iflet(value, maybe) try{} @finally{} [maybe unwrapWithBlock:^(value) {
//sp_else will be called if maybe contains nil.
#define sp_else } else:^() {
//finish sp_iflet body.
#define sp_iflet_end try{} @finally{} }];

@class SPNil; //is just a reprosentation of nil. For type property in case of nil
@protocol SPMaybe <NSObject>
@required

//returns maybe with value casted to type if isKindOf type or nil
+ (SPMaybe *_Nonnull)as:(id)valueToCast if:(Class) type;

//returns value casted to type if isKind of a type or will crah
+ (id)as:(id)valueToCast sure:(Class) type;

//returns wrapped class type
@property (nonatomic, readonly) Class type;

- (BOOL) isWeak;

//YES if nil, NO if value
- (BOOL) isNone;

//YES if value, NO if nil
- (BOOL) isSome;

//to get the value
//NOTE!: will make a crash in case of none
- (id _Nonnull) get;

//just unwrap the value or nil.
- (id _Nullable) unwrap;

//will return value if not nil or provided defaultValue if nil
- (id _Nonnull) getOrElse:(id _Nonnull)defaultValue;

//returns maybe itself if not nil or new maybe with provided insteadNilValue if nil
- (SPMaybe *_Nonnull)noNil:(id _Nonnull)insteadNilValue;

//unwrap maybe to value if not nil.
- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block;

//unwrap maybe to value or call else if nil.
- (void) unwrapWithBlock:(void(^)(id _Nonnull value))block else:(void(^)(void))elseBlock;

//unwrap a list of maybes. If atleast one of them equalt to nil all the list is supposed to be nil and else block will be called.
+ (void) unwrapSPMaybeGroup:(NSArray<id<SPMaybe> >*)group withBlock:(void(^)(NSArray *values)) unwrapBlock else:(void(^)(void))elseBlock;

- (void) map:(void(^)(id value)) mapBlock;
- (SPMaybe*) flatMap:(SPMaybe*(^)(id value)) mapBlock;

- (void (^ __nonnull)(void (^ _Nonnull)(id)))map;
- (SPMaybe* (^ __nonnull)(SPMaybe* (^ _Nonnull)(id)))flatMap;

@end

//SomePromiseMayBe is used to create a SPMaybe.
@interface SomePromiseMayBeCreator : NSObject <SPMaybe>
//create maybe with value
+ (SPMaybe *_Nonnull)some:(id _Nonnull)value;
//create maybe with nil
+ (SPMaybe *_Nonnull)none;
//if value - return maybe with value. if value == nil - returns maybe with nil.
+ (SPMaybe *_Nonnull)noNil:(id _Nullable)value;
+ (SPMaybe *_Nonnull)noNil:(id _Nullable)value weak:(BOOL) weak;

@end
