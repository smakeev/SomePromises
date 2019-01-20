//
//  SomePromiseExtend.h
//  SomePromises
//
//  Created by Sergey Makeev on 05/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>

//Each instance of NSObject or NSProxy can create an extend itself with valiable extention.
//Extention has nothing in commin with KVC or KVO.
@interface SPValueProvider : NSObject

@property(nonatomic)id value;

@end

typedef  void (^ SetterBlock)(SPValueProvider *_Nonnull currentValueProvider, id _Nullable newValue);
typedef  id (^ GetterBlock)(id value);
typedef void (^ SPListener)(id _Nullable);

@interface NSObject (SomePromiseExtend)

//create an extention with name.
//Extention will have a default value.
//User could provide setter and/or getter blocks.
//setter block will be called on each value change for the extention.
//getter on each access to the extention.
//setter block has valueProvider providing current value and newValue - what has been provided by user as a new value for an extention.
//getter has value parameter, user could return it or return anything else based on this value.
- (BOOL) spExtend:(NSString *_Nonnull)name defaultValue:(id _Nullable)value setter:(SetterBlock _Nullable) setter getter:(GetterBlock _Nullable) getter;

//get value by name. Will call get provided in spExtend if it has been provided.
- (id) spGet:(NSString *_Nonnull) name;

//set value to extention with name. Will call set provided in spExtend if it has been provided.
- (void) spSet:(NSString *_Nonnull) name value:(id _Nullable) value;

//Check if instance has extention with name.
- (BOOL) spHas:(NSString *_Nonnull) name;

//Remove an extention with name.
- (void) spUnset:(NSString *_Nonnull) name;

//Remove all extentions for instance
- (void) spClear;

//Call listener block with current value of extention and on each value change.
//Bind will be worknig while listener object is alive.
- (BOOL) bindTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block;

//Call listener block on each extention value change.
//Bind will be worknig while listener object is alive.
//listener provides a life time for bind. And is a owner of a bind.
- (BOOL) bindNextTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block;

//stop call listenerBlocks for listener.
//All binds with listener will be canceled.
- (BOOL) unbindFrom:(NSString *_Nonnull)name listener:(id _Nonnull)listener;

//The same methods. But in variant of returning blocks to provide this methods.
//Just to make possible to call them like so: NSString *name = objectInstance.spGet(@"name");
//or this block could be stored and be called later.
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SetterBlock _Nullable, GetterBlock _Nullable))spExtend;
- (id (^ __nonnull)(NSString *_Nonnull))spGet;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spSet;
- (BOOL (^ __nonnull)(NSString *_Nonnull))spHas;
- (void (^ __nonnull)(NSString *_Nonnull))spUnset;
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindToExtend;
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindNextToExtend;
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull))unbindFromExtend;

@end

@interface NSProxy (SomePromiseExtend)

- (BOOL) spExtend:(NSString *_Nonnull)name defaultValue:(id _Nullable)value setter:(SetterBlock _Nullable) setter getter:(GetterBlock _Nullable) getter;
- (id) spGet:(NSString *_Nonnull) name;
- (void) spSet:(NSString *_Nonnull) name value:(id _Nullable) value;
- (BOOL) spHas:(NSString *_Nonnull) name;
- (void) spUnset:(NSString *_Nonnull) name;
- (void) spClear;
- (BOOL) bindTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block;
- (BOOL) bindNextTo:(NSString *_Nonnull)name listener:(id _Nonnull)listener listenerBlock:(SPListener _Nullable)block;
- (BOOL) unbindFrom:(NSString *_Nonnull)name listener:(id _Nonnull)listener;

- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SetterBlock _Nullable, GetterBlock _Nullable))spExtend;
- (id (^ __nonnull)(NSString *_Nonnull))spGet;
- (void (^ __nonnull)(NSString *_Nonnull, id _Nullable))spSet;
- (BOOL (^ __nonnull)(NSString *_Nonnull))spHas;
- (void (^ __nonnull)(NSString *_Nonnull))spUnset;
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindToExtend;
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull, SPListener _Nullable))bindNextToExtend;
- (BOOL (^ __nonnull)(NSString *_Nonnull, id _Nonnull))unbindFromExtend;

@end

