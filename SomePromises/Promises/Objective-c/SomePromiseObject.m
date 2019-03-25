//
//  SomePromiseObject.m
//  SomePromises
//
//  Created by Sergey Makeev on 25/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseObject.h"
#import "SomePromiseEvents.h"
#import "SomePromiseExtend.h"
#import "SomePromiseUtils.h"
#import <objc/runtime.h>

id sp_callSuper(NSObject *instance, SEL selector)
{
	Method method = class_getInstanceMethod(instance.superclass, selector);
	IMP originalImp = method_getImplementation(method);
	id(* foo)(id, SEL) = (id (*)(__strong id, SEL))originalImp;
	return foo(instance, selector);
}

void sp_voidCallSuper(NSObject *instance, SEL selector)
{
	Method method = class_getInstanceMethod(instance.superclass, selector);
	IMP originalImp = method_getImplementation(method);
	void(* foo)(id, SEL) = (void (*)(__strong id, SEL))originalImp;
	foo(instance, selector);
}

IMP sp_superIMP(NSObject *instance, SEL selector)
{
	Method method = class_getInstanceMethod(instance.superclass, selector);
	return method_getImplementation(method);
}

@interface SomePromiseObject()
{
	Class _dynamicClass;
	NSMutableArray<void(^)(void)> *_deallocs;
	NSMutableDictionary<NSString*, id> *_vars;
	NSMutableDictionary<NSString*, void(^)(id result)> *_binds;
	NSMutableDictionary<NSString*, void(^)(id result)> *_bindsNext;
}

- (instancetype) initInternalWithClass:(Class)dynamicClass;

@end

@implementation SomePromiseObject

+ (id)createObjectBasedOn:(Class)baseClass protocols:(NSArray<Protocol*>* _Nullable)protocols bindLifetimeTo:(id _Nullable)lifeTimeObject definition:(void(^_Nullable)(SomePromiseObject*_Nonnull) )creationBlock
{

	Class dynamicClass = objc_allocateClassPair(baseClass, [SomePromiseUtils uuid].UTF8String, 0);
	
	for(Protocol *protocol in protocols)
	{
		class_addProtocol(dynamicClass, protocol);
	}
	
	SomePromiseObject *creator = nil;
	if(creationBlock)
	{
		creator = [[SomePromiseObject alloc] initInternalWithClass:dynamicClass];
		creationBlock(creator);
	}
	
	objc_registerClassPair(dynamicClass);
	NSObject *instance = [[dynamicClass alloc] init];
	
	if(lifeTimeObject)
	{
		[instance spExtend:@"___sp_self_agent" defaultValue:instance setter:nil getter:nil];
		
		@sp_avoidblockretain(instance)
		((NSObject*)lifeTimeObject).spDestroyListener(nil, ^(NSDictionary *msg){
			@sp_strongify(instance)
			guard(instance) else {return;}
			[instance spUnset:@"___sp_self_agent"];
		});
		@sp_avoidend(instance)
	}
	
	//add dealloc & vars if exist
	if(creator)
	{
		for(void(^dealloc)(void) in creator->_deallocs)
		{
			instance.spDestroyListener(nil, ^(NSDictionary *msg){
				dealloc();
			});
	
		}
		
		for(NSString *var in creator->_vars.allKeys)
		{
			[instance spExtend:var defaultValue:creator->_vars[var] setter:nil getter:nil];
		}
		
		for(NSString *var in creator->_binds.allKeys)
		{
			instance.bindToExtend(var, instance, creator->_binds[var]);
		}
		
		for(NSString *var in creator->_bindsNext.allKeys)
		{
		
			instance.bindNextToExtend(var, instance, creator->_binds[var]);
		}
		
	}
	
	return instance;
}

- (instancetype) initInternalWithClass:(Class)dynamicClass
{
	self = [super init];
	if(self)
	{
		_dynamicClass = dynamicClass;
		_deallocs = [NSMutableArray new];
		_vars = [NSMutableDictionary new];
		_binds = [NSMutableDictionary new];
		_bindsNext = [NSMutableDictionary new];
	}
	return self;
}

- (void) override:(SEL)selector with:(id _Nonnull)implementationBlock
{
	if (class_respondsToSelector(_dynamicClass, selector)) {
		class_replaceMethodWithBlock(_dynamicClass, selector, implementationBlock);
	} else {
		FATAL_ERROR(@"Override must override method from super class", @"Use create method");
	}
}

- (void) create:(SEL)selector with:(id _Nonnull)implementationBlock
{
	if (!class_respondsToSelector(_dynamicClass, selector)) {
		class_replaceMethodWithBlock(_dynamicClass, selector, implementationBlock);
	} else {
		FATAL_ERROR(@"Create must create method from super class", @"Use override method");
	}
}

- (void) addDealloc:(void(^)(void))implementationBlock
{
	[_deallocs addObject:[implementationBlock copy]];
}

- (void) addVar:(NSString *_Nonnull)name initial:(id _Nullable)value
{
	_vars[name] = value;
}

- (void) bindTo:(NSString *_Nonnull)name handler:(void(^_Nonnull)(id result))handler
{
	_binds[name] = [handler copy];
}

- (void) bindNextTo:(NSString *_Nonnull)name handler:(void(^_Nonnull)(id result))handler
{
	_bindsNext[name] = [handler copy];
}

@end
