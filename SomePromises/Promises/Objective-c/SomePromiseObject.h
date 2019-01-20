//
//  SomePromiseObject.h
//  SomePromises
//
//  Created by Sergey Makeev on 25/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>

///////////////////////////////////////////////////////////////
//
//SomePromiseObject class
//
//Provides you a way to create a dynamic anonymous class in objective-c
//
//	This class will be created and return it's the only instance.
//!NOTE:	Reusing the code of creating it will not only
//!	return new instance, but first create a new class for it.
//
//	Class will be inhereted from provided class and could conforms to
//	any protocols.
//	You may owerride methods. It is possible to call methods of super class
//	inside this implementation by using sp_callSuper and sp_voidCallSuper and sp_superIMP in case of parameters.
//	ex: self = sp_callSuper(self, @selector(init));
//!NOTE: not thread safe
////////////////////////////////////////////////////////////////

//to call super method implemetation inside your override if
//super method returns id and does not provide any parameters.
//example inside init overriding: self = sp_callSuper(self, @selector(init));
id sp_callSuper(NSObject *instance, SEL selector);

//to call super method implemetation inside your override if
//super method does not return anything and does not provide any parameters.
//example sp_voidCallSuper(self, @selector(methodForSuperTest));
void sp_voidCallSuper(NSObject *instance, SEL selector);

//The hardest variant
//If you have to call a super method with parameters
//In this case you will have t cast IMP yourself
//ex: let's say we have a method initWithValue:string:
//in super class
//Than to override it and call the super we will do:
//
//	IMP superImp = sp_superIMP(self, @selector(initWithValue:string:));
//	id(* foo)(id, SEL, int, NSString*) = (id (*)(__strong id, SEL, int, NSString*))superImp;
//  self = foo(self, @selector(initWithValue:string:), 56, @"test string");
//
//	NOTE!: this also could be used for simple types in returns.
IMP sp_superIMP(NSObject *instance, SEL selector);


@interface SomePromiseObject : NSObject

//create an instance
//
//parameters:
//		baseClass - class to inherit from
//		protocols - NSArray of protocols to conform to
//		lifeTimeObject - object to bind lifetime.
//						 It works only if there are no strong ref. to our instance.
//		definition - block to make a class. Get
+ (id)createObjectBasedOn:(Class)baseClass protocols:(NSArray<Protocol*>* _Nullable)protocols bindLifetimeTo:(id _Nullable)lifeTimeObject definition:(void(^_Nullable)(SomePromiseObject*_Nonnull creator))creationBlock;

//override method or add new.
// selector - is a selector for method to be owerriden or added
// implementationBlock - is a block to change implementation.
// return type (NSObject *self, parameters of the method)
- (void) override:(SEL)selector with:(id _Nonnull)implementationBlock;

//add dealloc. block to be called on object destroy.
//[creator addDealloc:^{
//	..code..
// }];
- (void) addDealloc:(void(^)(void))implementationBlock;

//to add var to object. It is an SPExtend.
- (void) addVar:(NSString *_Nonnull)name initial:(id _Nullable)value;

//call handler with current value and on value change
- (void) bindTo:(NSString *_Nonnull)name handler:(void(^_Nonnull)(id result))handler;

//call handler on value change
- (void) bindNextTo:(NSString *_Nonnull)name handler:(void(^_Nonnull)(id result))handler;

@end
