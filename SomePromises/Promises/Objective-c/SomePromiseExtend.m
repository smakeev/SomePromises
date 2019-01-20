//
//  SomePromiseExtend.m
//  SomePromises
//
//  Created by Sergey Makeev on 05/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseExtend.h"
#import "SomePromiseUtils.h"

@interface SPValueProvider()
{
   SomeClassBox *_classBox;
}

@end

@implementation SPValueProvider

- (instancetype)initWithClassBox:(SomeClassBox*)classBox
{
   self = [super init];
	
   if(self)
   {
      _classBox = classBox;
   }
	
   return self;
}

- (id)value
{
   return _classBox.value;
}

- (void)setValue:(id)value
{
    _classBox.value = value;
}

@end

@class __SomePromiseExtendStore;
static __SomePromiseExtendStore *_storeInstance = nil;

@interface __SomePromiseExtendItem : NSObject

@property(nonatomic, strong) SomeClassBox *value;
@property(nonatomic, copy) SetterBlock setter;
@property(nonatomic, copy) GetterBlock getter;

@end

@implementation __SomePromiseExtendItem

- (instancetype) initWithValue:(SomeClassBox*)value setter:(SetterBlock)setter getter:(GetterBlock)getter
{
    self = [super init];
    if(self)
    {
		self.value = value;
		if(setter) {
		   self.setter = setter;
		} else {
		   self.setter = ^(SPValueProvider *currentValueProvider, id newValue){
		      currentValueProvider.value = newValue;
		   };
		}
		
		if(getter) {
		   self.getter = getter;
		} else {
		   self.getter = ^(id value) {
		      return value;
		   };
		}
	}
	return self;
}

@end

@interface __SomePromiseExtendStore : NSObject
{
    NSMapTable<id, NSDictionary<NSString*, __SomePromiseExtendItem*>*> *_store;
    dispatch_queue_t _syncQueue;
}

@end

@implementation __SomePromiseExtendStore
+ (instancetype) instance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
	{
	    _storeInstance = [[__SomePromiseExtendStore alloc] init];
	});
	return _storeInstance;
}

- (instancetype) init
{
   self = [super init];
   if(self)
   {
      _store = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory  valueOptions:NSMapTableStrongMemory];
      _syncQueue = dispatch_queue_create("__SomePromiseExtendStore_queue", DISPATCH_QUEUE_SERIAL);
   }
	
   return self;
}

- (BOOL) addElementTo:(id)target elementName:(NSString*)name value:(id)value setter:(SetterBlock)setter getter:(GetterBlock)getter
{
    __block BOOL result = NO;
    dispatch_sync(_syncQueue, ^{
		if([self->_store objectForKey:target] == nil)
		{
			NSMutableDictionary *extentionDict = [NSMutableDictionary new];
			extentionDict[name] = [[__SomePromiseExtendItem alloc] initWithValue:[[SomeClassBox alloc] initWithValue:value] setter:setter getter:getter];
			[self->_store setObject:extentionDict forKey:target];
			result = YES;
		}
		else
		{
		    NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
			guard([extentionDict objectForKey:name] == nil) else {result = NO; return;}
			extentionDict[name] = [[__SomePromiseExtendItem alloc] initWithValue:[[SomeClassBox alloc] initWithValue:value] setter:setter getter:getter];
			result = YES;
		}
	});
	
	return result;
}

- (id) get:(NSString*)name target:(id)target
{
     __block id result = nil;
	 dispatch_sync(_syncQueue, ^{
		 NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {FATAL_ERROR(@"Wrong Target for SP extend", @"object does not have any extentions yet");}
		 __SomePromiseExtendItem *item = extentionDict[name];
		 guard(item) else {FATAL_ERROR(@"Wrong extend name", @"object instance does not have extend with provided name");}
		 result = item.getter(item.value.value);
	 });
	 
	 return result;
}

- (void) set:(NSString*)name target:(id)target newValue:(id)newValue
{
	 dispatch_sync(_syncQueue, ^{
		 NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {FATAL_ERROR(@"Wrong Target for SP extend", @"object does not have any extentions yet");}
		 __SomePromiseExtendItem *item = extentionDict[name];
		 guard(item) else {FATAL_ERROR(@"Wrong extend name", @"object instance does not have extend with provided name");}
		 SPValueProvider *provider = [[SPValueProvider alloc] initWithClassBox:item.value];
		 item.setter(provider, newValue);
	 });
}

- (BOOL) has:(NSString*)name target:(id)target
{
   __block BOOL result = NO;
	 dispatch_sync(_syncQueue, ^{
		 NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {return;}
		 __SomePromiseExtendItem *item = extentionDict[name];
		 guard(item) else {return;}
		 result = YES;
	 });
	
	 return result;
}

- (void) unset:(NSString*)name target:(id)target
{
   dispatch_sync(_syncQueue, ^{   
 		 NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {FATAL_ERROR(@"Wrong Target for SP extend", @"object does not have any extentions yet");}
		 __SomePromiseExtendItem *item = extentionDict[name];
		 guard(item) else {FATAL_ERROR(@"Wrong extend name", @"object instance does not have extend with provided name");}
		 extentionDict[name] = nil;
   });
}

- (void) clearForTarget:(id)target
{
	dispatch_sync(_syncQueue, ^{
	     NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {FATAL_ERROR(@"Wrong Target for SP extend", @"object does not have any extentions yet");}
	     [extentionDict removeAllObjects];
	});
}

- (BOOL) bind:(NSString*)name target:(id)target listener:(id)listener block:(SPListener)block
{
    __block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		 NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {return;}
		 __SomePromiseExtendItem *item = extentionDict[name];
		 guard(item) else {return;}
		 item.value.bind(listener, block);
		 result = YES;
    });
	
    return result;
}

- (BOOL) bindNext:(NSString*)name target:(id)target listener:(id)listener block:(SPListener)block
{
    __block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		 NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		 guard(extentionDict) else {return;}
		 __SomePromiseExtendItem *item = extentionDict[name];
		 guard(item) else {return;}
		 item.value.bindNext(listener, block);
		 result = YES;
    });
	
    return result;
}

- (BOOL) unbindbind:(NSString*)extend arget:(id)target listener:(id)listener
{
	__block BOOL result = NO;
	dispatch_sync(_syncQueue, ^{
		NSMutableDictionary *extentionDict = (NSMutableDictionary*)[self->_store objectForKey:target];
		guard(extentionDict) else {return;}
		 __SomePromiseExtendItem *item = extentionDict[extend];
		 guard(item) else {return;}
		 item.value.unbind(listener);
		 result = YES;
	});
	
	return result;
}

@end


static BOOL __sp_extend(id selfPointer, NSString *name, id defaultValue, SetterBlock setter, GetterBlock getter)
{
   return [[__SomePromiseExtendStore instance] addElementTo:selfPointer elementName:name value:defaultValue setter:setter getter:getter];
}

static id __sp_get(id selfPoiner, NSString *name)
{
   return [[__SomePromiseExtendStore instance] get:name target:selfPoiner];
}

static void __sp_set(id selfpointer, NSString *name, id value)
{
   [[__SomePromiseExtendStore instance] set:name target:selfpointer newValue:value];
}

static BOOL __sp_has(id selfpointer, NSString *name)
{
   return  [[__SomePromiseExtendStore instance] has:name target:selfpointer];
}

static void __sp_unset(id selfPointer, NSString *name)
{
   [[__SomePromiseExtendStore instance] unset:name target:selfPointer];
}

static void __sp_clear(id selfPointer)
{
   [[__SomePromiseExtendStore instance] clearForTarget:selfPointer];
}

static BOOL __sp_bind(id selfPointer, NSString *name, id listener, SPListener block)
{
   return [[__SomePromiseExtendStore instance] bind:name target:selfPointer listener:listener block:block];
}

static BOOL __sp_bindNext(id selfPointer, NSString *name, id listener, SPListener block)
{
   return [[__SomePromiseExtendStore instance] bindNext:name target:selfPointer listener:listener block:block];
}

static BOOL __sp_unbind(id selfPointer, NSString *extend, id listener)
{
	return [[__SomePromiseExtendStore instance] unbindbind:extend arget:selfPointer listener:listener];
}

@implementation NSObject (SomePromiseExtend)

- (BOOL) spExtend:(NSString *_Nonnull)name defaultValue:(id _Nullable)value setter:(SetterBlock _Nullable) setter getter:(GetterBlock _Nullable) getter
{
   return __sp_extend(self, name, value, setter, getter);
}

- (id) spGet:(NSString *_Nonnull) name
{
   return __sp_get(self, name);
}
- (void) spSet:(NSString *_Nonnull) name value:(id _Nullable) value
{
    __sp_set(self, name, value);
}

- (BOOL) spHas:(NSString *_Nonnull) name
{
   return __sp_has(self, name);
}
- (void) spUnset:(NSString *_Nonnull) name
{
	__sp_unset(self, name);
}

- (void) spClear
{
   __sp_clear(self);
}

- (BOOL) bindTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block
{
  return __sp_bind(self, name, listener, block);
}

- (BOOL) bindNextTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block;
{
  return __sp_bindNext(self, name, listener, block);
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SetterBlock _Nullable, GetterBlock _Nullable))spExtend
{
    return [^(NSString *name, id defaultValue, SetterBlock setterBlock, GetterBlock getterBlock){
		return [self spExtend:name defaultValue:defaultValue setter:setterBlock getter:getterBlock];
	} copy];
}

- (id (^ __nonnull)(NSString *_Nonnull))spGet
{
	return [^(NSString *name){
	   return [self spGet:name];
	}  copy];
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spSet
{
   return [^(NSString *name, id value){
      [self spSet:name value:value];
   } copy];
}

- (BOOL (^ __nonnull)(NSString *_Nonnull))spHas
{
   return [^(NSString *name){
       return [self spHas:name];
   } copy];
}

- (void (^ __nonnull)(NSString *_Nonnull))spUnset
{
   return [^(NSString *name) {
      [self spUnset:name];
   } copy];
}

- (BOOL) unbindFrom:(NSString *_Nonnull)name listener:(id _Nonnull)listener
{
	return __sp_unbind(self, name, listener);
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindToExtend
{
   return [^(NSString *_Nonnull name, id _Nonnull listener, SPListener _Nullable block)
   {
       return [self bindTo:name listener:listener listenerBlock:block];
   } copy];
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindNextToExtend;
{
   return [^(NSString *_Nonnull name, id _Nonnull listener, SPListener _Nullable block)
   {
       return [self bindNextTo:name listener:listener listenerBlock:block];
   } copy];
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull))unbindFromExtend
{
   return [^(NSString *_Nonnull name, id _Nonnull listener)
   {
       return [self unbindFrom:name listener:listener];
   } copy];
}

@end


@implementation NSProxy (SomePromiseExtend)

- (BOOL) spExtend:(NSString *_Nonnull)name defaultValue:(id _Nullable)value setter:(SetterBlock _Nullable) setter getter:(GetterBlock _Nullable) getter
{
      return __sp_extend(self, name, value, setter, getter);
}

- (id) spGet:(NSString *_Nonnull) name
{
   return __sp_get(self, name);
}

- (void) spSet:(NSString *_Nonnull) name value:(id _Nullable) value
{
  __sp_set(self, name, value);
}

- (BOOL) spHas:(NSString *_Nonnull) name
{
  return __sp_has(self, name);
}

- (void) spUnset:(NSString *_Nonnull) name
{
   	__sp_unset(self, name);
}

- (void) spClear
{
  __sp_clear(self);
}

- (BOOL) bindTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block
{
   return __sp_bind(self, name, listener, block);
}

- (BOOL) bindNextTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block;
{
  return __sp_bindNext(self, name, listener, block);
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SetterBlock _Nullable, GetterBlock _Nullable))spExtend
{
    return [^(NSString *name, id defaultValue, SetterBlock setterBlock, GetterBlock getterBlock){
		return [self spExtend:name defaultValue:defaultValue setter:setterBlock getter:getterBlock];
	} copy];
}

- (id (^ __nonnull)(NSString *_Nonnull))spGet
{
	return [^(NSString *name){
	   return [self spGet:name];
	}  copy];
}

- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spSet
{
   return [^(NSString *name, id value){
      [self spSet:name value:value];
   } copy];
}

- (BOOL (^ __nonnull)(NSString *_Nonnull))spHas
{
   return [^(NSString *name){
       return [self spHas:name];
   } copy];
}

- (void (^ __nonnull)(NSString *_Nonnull))spUnset
{
   return [^(NSString *name) {
      [self spUnset:name];
   } copy];
}

- (BOOL) unbindFrom:(NSString *_Nonnull)name listener:(id _Nonnull)listener
{
	return __sp_unbind(self, name, listener);
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindToExtend
{
   return [^(NSString *_Nonnull name, id _Nonnull listener, SPListener _Nullable block)
   {
       return [self bindTo:name listener:listener listenerBlock:block];
   } copy];
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindNextToExtend;
{
   return [^(NSString *_Nonnull name, id _Nonnull listener, SPListener _Nullable block)
   {
       return [self bindNextTo:name listener:listener listenerBlock:block];
   } copy];
}

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull))unbindFromExtend
{
   return [^(NSString *_Nonnull name, id _Nonnull listener)
   {
       return [self unbindFrom:name listener:listener];
   } copy];
}

@end
