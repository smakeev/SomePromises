//
//  SomePromiseUtils.h
//  SomePromises
//
//  Created by Sergey Makeev on 26/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//
/*************************************************
* SomePromiseUtils.h contains functions, macroses and classes with useful functionality.
*	The library uses them itself inside the implementation.
*
*	Contain:
*		Macroses:
*			@sp_avoidblockretain  avoid retainig of var by block
*			@sp_strongify	change var to __strong var (inside the @sp_avoidblockretain)
*			@sp_weakify change var to __weak var
*			@sp_avoidend end of @sp_avoidblockretain
*
*			guard check for condition. Usually checking vars for nil.
*
*			BLOCK_SIGNATURE_AVAILABLE to get signature of a block by calling __BlockSignature__(block)
*
*			FATAL_ERROR(title, message)  crash the app.
*
*			Defer functionality:
*			deferLevelTag(tag)
*			externalDefer(deferTag, deferNumber, code)
*
*			class SomePromiseUtils - several class(static) methods to be
*				provides methods to check if protocol/class has method with selector
*				provide possibility to extend class by protocol with default implementations of methods.
*			SomeClassBox - simple container over the object. Allows to bind to it's value
*
**************************************************/
#import <Foundation/Foundation.h>

//=======================================================================================================================
//*	block retain cycles handling
//=======================================================================================================================
/*************************************************
*
*  @sp_avoidblockretain @sp_strongify @sp_weakify @sp_avoidend
*
*	Methods to avoid retain cycles in blocks.
*
*	The standard way to avoid retain cycle is using __weak pointer on self before block
*	And __strong inside the block.
*
*	This solution has problem with using NSAssert and other macrosses with self inside.
*	Also very often it is easy to forget self-> before iVar.
*	The solution could be change self to __weak self (like @weakify(self))
*	And @strongify(self) inside the block.
*	But in this case we have changed self (weak self) till the end of stack with block.
*
*	This solution contains 3 parts.
*   1st. @sp_avoidblockretain(self) make self weak. But also keeps it's in another strong variable.
*	2nd. @sp_strongify(self) or @sp_weakify(self) makes self strong (weak) inside block.
*		Note in case of nested blocks each block should has @sp_strongify or sp_weakify. Not only the first one.
*		The best way is get it as a rule to each blcok.
*
*	3d. @sp_avoidend finishes the changed self (weak self). After this point self means the same as before the @sp_avoidblockretain(self)
*		Note: actually @sp_avoidend does not need (self), you may pass anything else here.
*
*	If you need to pass several variables as weak you may use nested @sp_avoidblockretain:
*
*		@sp_avoidblockretain(var1)
*		@sp_avoidblockretain(var2)
*		@sp_avoidblockretain(var3)
*
*       block body:
*		@sp_strongify(var1)
*		@sp_strongify(var2)
*       @sp_strongify(var3)
*
*		after the block body.
*
*		@sp_avoidend(var1)
*		@sp_avoidend(var2)
*		@sp_avoidend(var3)
*
*		example:
* 		@sp_avoidblockretain(self)
*		((NSObject*)value).spDestroyListener(nil, ^(NSDictionary *msg){
*			@sp_strongify(self)
*			guard(self && self.array) else return;
*			if(self.array.autoshrink)
*			{
*				[self.array shrink];
*			}
*		});
*		@sp_avoidend(self)
*
*************************************************/
#define sp_avoidblockretain(arg) \
							try {} @finally{ \
							__strong id __private_##arg##_keeper = arg; \
							__weak typeof(arg) __private_weak_##arg##_keeper  __attribute__((unused)) = __private_##arg##_keeper; \
							__weak typeof(arg) arg  __attribute__((unused)) = __private_##arg##_keeper; \

#define sp_avoidend(arg) \
							try {} @finally{} \
							}


#define sp_strongify(arg) \
							try {} @finally{} \
							__strong typeof(arg) arg __attribute__((unused)) = __private_weak_##arg##_keeper;

#define sp_weakify(arg) \
							try {} @finally{} \
							__weak typeof(arg) arg __attribute__((unused)) = __private_weak_##arg##_keeper;

//=======================================================================================================================
//*	guard
//=======================================================================================================================
/***********************************************************************************************************************
*	guard
*	guard is a macro to check anything as if, but with no then part (only else is available)
*	Usually can be used for checking variables for nil.
*	ex:
*
*	SomeObject *object = getObjectOrNil();
*	guard(object) else { return;}
*
*	In fact you can use it for any conditions.
*	guard(condition) else {code}
*	It will be equal to if(!condition) {code}
************************************************************************************************************************/

#define guard(a) if(a) {}

//=======================================================================================================================
//*	block signature
//=======================================================================================================================
/***********************************************************************************************************************
*
*	BLOCK_SIGNATURE_AVAILABLE
*
*	To get block signature.
*
*	Place this macross at the begginig of file where you need to get ablock signature.
* 	Than you could just call __BlockSignature__ with block as a parameter. And will get it's signature
*
*	ex:
*		[NSMethodSignature signatureWithObjCTypes:__BlockSignature__(creationBlock)];
*
************************************************************************************************************************/

#define BLOCK_SIGNATURE_AVAILABLE static const char *__BlockSignature__(id blockObj)\
{\
    struct Block_literal_1 *block = (__bridge void *)blockObj;\
    struct Block_descriptor_1 *descriptor = block->descriptor;\
    assert(block->flags & BLOCK_HAS_SIGNATURE);\
    int offset = 0;\
    if(block->flags & BLOCK_HAS_COPY_DISPOSE)\
        offset += 2;\
    return (char*)(descriptor->rest[offset]);\
}\

//=======================================================================================================================
//*	error
//=======================================================================================================================
/***********************************************************************************************************************
*	FATAL_ERROR(title, message)
*	Rises an exception with message and title.
*
*	title - NSString title for exception
*	message - NSString. Message for exception.
*
************************************************************************************************************************/

#define FATAL_ERROR(title, message)  [NSException raise:title format:message];

/***********************************************************************************************************************
*
*	NSError* rejectionErrorWithText(NSString* description, NSInteger code)
*	create an error to be used to reject the promise.
*	perams:
*	description - NSString title for error
*	code - NSInteger, error code. There are some standard codes. See SomePromiseErrors enum in SomePromiseTypes.h
*
************************************************************************************************************************/
NSError* rejectionErrorWithText(NSString* description, NSInteger code);
//=======================================================================================================================
//*	defer
//=======================================================================================================================
/************************************************************************************************************************
*
*	Defer
*		to delay something until a later time.
*		Defer block will be called when the stack part roll back.
*		Defer could be in the same stack level or in another.
*		In case of another you may use deferLevelTag(tag) inside the stack
*
*
*
*************************************************************************************************************************/

/************************************************************************************************************************
*
*	deferLevelTag(tag)
*			Mark a stack level with a tag.
*			tag could be used inside defer
*
*************************************************************************************************************************/
#define deferLevelTag(tag)  [[DeferPools instance].somePromiseDeferLocker lock];\
                            NSMutableDictionary *tag = [NSMutableDictionary new];\
                            if(areThereBlocksForTagWithName([NSString stringWithUTF8String:#tag]))\
                            {\
								addAllBlocksToTagForTagWithName(tag, [NSString stringWithUTF8String:#tag]);\
							}\
							storeTag(tag, [NSString stringWithUTF8String:#tag]);\
                            [[DeferPools instance].somePromiseDeferLocker unlock];\

/************************************************************************************************************************
*
*	externalDefer(deferTag, deferNumber, code)
*							Call the code (block) when stack with deferTag rolls back.
*
*							Params:
*								deferTag -  tag for stack. Just any word without ""
*							 deferNumber -  should be unique for externalDefer with the same tag. Just an int.
*											Does not get any meaning in this version.
*								    code -  void(^)(void) block. This block will be implemented after stack with tag finished
*
*							ex:
*
*   externalDefer(firstTag, 0, ^{
*	   NSLog(@"firstTag Defer code 0");
*   });
*	{
*			{
*				....
*				{
*					deferLevelTag(firstTag)
*				}
*				....
*			}
*	}
*************************************************************************************************************************/

#define externalDefer(deferTag, deferNumber, code) [[DeferPools instance].somePromiseDeferLocker lock];\
												  id tag##_##deferTag##deferNumber = getDeferTagByName([NSString stringWithUTF8String:#deferTag]);\
												  if(tag##_##deferTag##deferNumber)\
												  {\
                                                    addBlockToTagWithNumber(tag##_##deferTag##deferNumber, deferNumber, code);\
                                                  } else\
                                                  {\
                                                    addBlockToPoolWithTagName(deferNumber, code, [NSString stringWithUTF8String:#deferTag]);\
												  }\
                                                  [[DeferPools instance].somePromiseDeferLocker unlock];\
/************************************************************************************************************************
*
*	defer(deferNumber, code) - if defer is on the same stack level as should be it's tag.
*							Call the code (block) when stack rolls back.
*
*							Params:
*
*							 deferNumber -  must be unique for externalDefer with the same tag. Just an int.
*											Does not get any meaning in this version.
*								    code -  void(^)(void) block. This block will be implemented after stack with tag finished
*							ex:
*
*								defer(0, ^{
*       								NSLog(@"Defer code 0);
*								});
*								NSLog(@"End of stack");
*
*								Result:
*										End of stack
*										Defer code 0
*
*************************************************************************************************************************/
#define defer(deferNumber, code) id _##deferNumber = [Defer block:code]; [_##deferNumber doNothing];

//=======================================================================================================================
//*	class	SomePromiseUtils
//=======================================================================================================================
/************************************************************************************************************************
* 	class SomePromiseUtils
*
*	conains static(class) methods for diff. tasks.
*
*************************************************************************************************************************/
@interface SomePromiseUtils : NSObject

/************************************************************************************************************************
*
* + (NSError*) errorFromException:(NSException*)exception
*		Makes NSError from the exception.
*
*		parameters:
*				(NSException*)exception - an exception to be an error source
*		returns:
*			NSerror - representation of the exception as an error.
*
*		Internaly it is needed due to promise fails with error, not with exception.
*
*
************************************************************************************************************************/
+ (NSError*) errorFromException:(NSException*)exception;

/************************************************************************************************************************
*	+ (BOOL) protocol:(Protocol*)protocol hasRequiredInstanceMethodWithselector:(SEL)selector
*			check if protocol has instance method with selector and it is required
*
*	+ (BOOL) protocol:(Protocol*)protocol hasRequiredClassMethodWithselector:(SEL)selector
*			check if protocol has class/static method with selector and it is required
*
*	+ (BOOL) protocol:(Protocol*)protocol hasOptionalInstanceMethodWithselector:(SEL)selector
*			check if protocol has instance method with selector and it is optional
*
*	+ (BOOL) protocol:(Protocol*)protocol hasOptionalClassMethodWithselector:(SEL)selector
*			check if protocol has class/static method with selector and it is optional
*
*	+ (BOOL) protocol:(Protocol*)protocol hasMethodWithSelector:(SEL)selector
*			check if protocol has method with selector. It could be instance or class/static and optional or required
*
*	parameters:
*		protocol - protocol to check
*		selector - selector of method to search
*
*		returns:
*			The result of method searching in protocol
*
*
************************************************************************************************************************/
+ (BOOL) protocol:(Protocol*)protocol hasRequiredInstanceMethodWithselector:(SEL)selector;
+ (BOOL) protocol:(Protocol*)protocol hasRequiredClassMethodWithselector:(SEL)selector;
+ (BOOL) protocol:(Protocol*)protocol hasOptionalInstanceMethodWithselector:(SEL)selector;
+ (BOOL) protocol:(Protocol*)protocol hasOptionalClassMethodWithselector:(SEL)selector;
+ (BOOL) protocol:(Protocol*)protocol hasMethodWithSelector:(SEL)selector;

/************************************************************************************************************************
*
*	+ (BOOL) class:(Class)class hasMethod:(SEL)selector
*		check if class has method with selector
*		class must have the implementation of the method to get YES here. Not only declaration (such as optiona in protocol)
*	parameters:
*		class - class to check
*		selector - selector of method to search
*
*		returns:
*			The result of method searching in class
*
************************************************************************************************************************/
+ (BOOL) class:(Class)class hasMethod:(SEL)selector;

/************************************************************************************************************************
*	+ (void) makeProtocolOriented:(Class)class protocol:(Protocol*) protocol extention:(Class)extentionClass whereSelf:(Protocol*) selfRestrictions
*	make a protocol to have a default implementations of methods for classes with some types limitations.
*	Class will have protocol's default implementations.
*	Many classes could have the same default implementations of protocol's methods
*   If class overrides some method, it will be overriden for this class only
* 	Other classes will be use default impmlemetation or can override the method itselfs.
*	Usage:
*		It must be called in a class +load method. (class that wants to use default implementaion)
*		You should provide a default implemetation class. This is a stub class. it should conform to the protocol and conforms to restrictions protocols.
*		This allow you to have several default implementations depends on the class (wich you want to extend) type.
*	parameters:
*		class - class that will use default implementations. Due to you will call this method inside + load method this always would be [self class]
* 		protocol - a protocol to extend the class with default implementation
* 	extentionClass - a stub class with default implementation.
*	selfRestrictions - is a protocol, stub class and your class must conform.
*	ex:
*		For example just take a look to SomePromiseFeature and SomePromise class. They both use SomePromiseChainMethodsExecutorStrategy as a default implementation of
*		SomePromiseChainMethods and SomePromiseChainPropertyMethods protocols.
*
************************************************************************************************************************/
+ (void) makeProtocolOriented:(Class)class protocol:(Protocol*) protocol extention:(Class)extentionClass whereSelf:(Protocol*) selfRestrictions;

/************************************************************************************************************************
*
*	+ (NSString *)uuid;
*	returns an unique(random) uuid string. Is used for anonymous dynamic class name  (see SomePromiseObject.h)
*
************************************************************************************************************************/
+ (NSString *)uuid;

@end
//=======================================================================================================================
//*	class	SomeClassBox
//=======================================================================================================================
/************************************************************************************************************************
*
*	class	SomeClassBox
*	provides a simple conteiner for a class with template type T.
*	Allows to bind to it's value change to get updated by calling listener - a block with new value as a parameter.
*	Thread safe.
*	NOTE!: if value of a ClassBox is mutable it's change will not impact listeners(observers) to get updated.
*	Only changing of value property is triggered.
************************************************************************************************************************/
@interface SomeClassBox<__covariant T> : NSObject
typedef void (^SPListener)(T _Nullable);

//an object to listen to
@property(nonatomic) T _Nullable value;

/************************************************************************************************************************
*
*	+ (instancetype)empty
*
*	returns an empty class box.
*	empty means it's value property is nil
*
************************************************************************************************************************/
+ (instancetype)empty;
/************************************************************************************************************************
*
*	- (instancetype _Nullable) initWithValue:(T _Nonnull ) value
*
*	standard init method.
*	it's value property willl be set to parameter value.
*
************************************************************************************************************************/

- (instancetype _Nullable) initWithValue:(T _Nonnull ) value;

/************************************************************************************************************************
*
*	- (void) skip
*   set value to nil, but not call any observer.
*
************************************************************************************************************************/
- (void) skip;

/************************************************************************************************************************
*
*	- (void) skipValue:(id)value
*   set value to value, but not call any observer.
*
************************************************************************************************************************/
- (void) skipValue:(id)value;

/************************************************************************************************************************
*
*	- (void) bind:(id)target listener:(SPListener)listener;
*  call listener with current value and then call it for each value change.
*
*	params:
*		target - is a listener owner. An object representing a listener.
*				 Targer is stored weakly. If it becomes nil listener will no longer get updates.
*				 It will be deleted also. So it is used for listener lifetime.
*				 NOTE!: if you want some listener to be permanent just call it with some always existing target.
*				 Also target can be used to unsubscribe for particular listeners.
*				 NOTE!: There could be many listeners for one target. They all will be deleted on unsubscribe for target.
*		listener - a block with one parameter. Parameter represents new value of a ClassBox.
*
************************************************************************************************************************/
- (void) bind:(id)target listener:(SPListener)listener;

/************************************************************************************************************************
*
*	- (void) bindNext:(id)target listener:(SPListener)listener;
*  call listener for each value change.
*  NOTE!: does not call listener with the current value.
*
*	params:
*		target - is a listener owner. An object representing a listener.
*				 Targer is stored weakly. If it becimes nil listener will no longer get updates.
*				 It will be deleted also. So it is used for listener lifetime.
*				 NOTE!: if you want some listener to be permanent just call it with some always existing target.
*				 Also target can be used to unsubscribe for particular listeners.
*				 NOTE!: Thre could be many listeners for one target. They all will be deleted on unsubscribe for target.
*		listener - a block with one parameter. Parameter represents new value of a ClassBox.
*
************************************************************************************************************************/
- (void) bindNext:(id)target listener:(SPListener)listener;

/************************************************************************************************************************
*
*	- (void) bindOnce:(id)target listener:(SPListener)listener;
*  call listener for one value change. Listener will be deleted after been informed once.
*  NOTE!: does not call listener with the current value.
*
*	params:
*		target - is a listener owner. An object representing a listener.
*				 Targer is stored weakly. If it becimes nil listener will no longer get updates.
*				 It will be deleted also. So it is used for listener lifetime.
*				 NOTE!: if you want some listener to be permanent just call it with some always existing target.
*				 Also target can be used to unsubscribe for particular listeners.
*				 NOTE!: Thre could be many listeners for one target. They all will be deleted on unsubscribe for target.
*		listener - a block with one parameter. Parameter represents new value of a ClassBox.
*
************************************************************************************************************************/
- (void) bindOnce:(id)target listener:(SPListener)listener;

/************************************************************************************************************************
*
*	- (void) unbind:(id _Nonnull )object;
*  	delete listeners for target == object
*
*	params:
*		object - is a listener owner. An object representing a listener.
*				 object was stored weakly on binding.
*
************************************************************************************************************************/
- (void) unbind:(id _Nonnull )object;

/************************************************************************************************************************
*
*	- (void) unbindAll;
*  	delete listeners for all targets
*	No listeners will be presented after this call
*
************************************************************************************************************************/
- (void) unbindAll;

/************************************************************************************************************************
*
*	- (void) callListenersForward;
*	Call all listeners for all targets with current value.
*	NOTE!: All once listeners will be deleted after that.
*
************************************************************************************************************************/
- (void) callListenersForward;

/************************************************************************************************************************
*
*	- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bind;
*	Returns a block wich could make bind. Just call this block with target and listener parameters.
*	NOTE!: This (returned) block is already copied in hip.
*
*	box.bind(target, listener);
*
************************************************************************************************************************/
- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bind;

/************************************************************************************************************************
*
*	- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bindNext;
*	Returns a block wich could make bindNext. Just call this block with target and listener parameters.
*	NOTE!: This (returned) block is already copied in hip.
*
*	box.bindNext(target, listener);
*
************************************************************************************************************************/
- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bindNext;

/************************************************************************************************************************
*
*	- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bindOnce;
*	Returns a block wich could make bindOnce. Just call this block with target and listener parameters.
*	NOTE!: This (returned) block is already copied in hip.
*
*	box.bindNext(target, listener);
*
************************************************************************************************************************/
- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bindOnce;

/************************************************************************************************************************
*
*	- (void (^ __nonnull)(id _Nonnull))unbind;
*	Returns a block wich could make unbind. Just call this block with target parameter.
*	NOTE!: This (returned) block is already copied in hip.
*
*	box.unbind(target);
*
************************************************************************************************************************/
- (void (^ __nonnull)(id _Nonnull))unbind;

@end

//=======================================================================================================================
//*	class	SomeListener
//=======================================================================================================================
/************************************************************************************************************************
*
*	class	SomeListener
*	provides a simple listener for a ClassBox.
*	Allows to bind to it's value change to get updated by calling listener block or by calling method on:
*	NOTE!: Is not thread safe. But ClassBox is threadSafe and SomeListener only provides a  block or a method to be called
*
*	If use on: method to be notefied than it requires subclassing. By default on: method does nothing.
*
*	NOTE!: It could listen many ClassBoxes in same time.
*
************************************************************************************************************************/
@interface SomeListener : NSObject

/************************************************************************************************************************
*
*	- (instancetype) init;
*	provides a standard init method.
*	Choosing this init you choose using on: method instead of block to be used as a listener of a ClassBox
*	This means you should subclass SomeListener and call this init as [super init] form your subclassed init method.
*
*	NOTE!:Could be used as Dynamic class (see SomePromiseObject.h).
*	NOTE!: It uses self as a target for listener. (see MyClass bind method description to read about targets)
*
************************************************************************************************************************/
- (instancetype) init;

/************************************************************************************************************************
*
*	- (instancetype) initWithBlock;
*	provides a standard init method with parameter.
*	Choosing this init you choose using block to be used as a listener of a ClassBox
*	This means you should not (but can if you want).
*	NOTE!: It uses self as a target for listener. (see MyClass bind method description to read about targets)
*
************************************************************************************************************************/
- (instancetype) initWithBlock:(void (^)(id _Nullable))listener;

/************************************************************************************************************************
*
*	- (void) listenTo:(SomeClassBox*)object;
*	Start listening for object(ClassBox)'s value change.
*	Will be called with current object's value.
*
************************************************************************************************************************/
- (void) listenTo:(SomeClassBox*)object;

/************************************************************************************************************************
*
*	- (void) listenNextTo:(SomeClassBox*)object;
*	Start listening for object(ClassBox)'s value change.
*	Will be called with new values only.
*
************************************************************************************************************************/
- (void) listenNextTo:(SomeClassBox*)object;

/************************************************************************************************************************
*
*	- (void) listenOnce:(SomeClassBox*)object;
*	Start listening for object(ClassBox)'s value change.
*	Will be called with new values only once.
*
************************************************************************************************************************/
- (void) listenOnce:(SomeClassBox*)object;

/************************************************************************************************************************
*
*	- (void) stopListenTo:(SomeClassBox*)object;
*	Stop listening for object(ClassBox)'s value change.
*
************************************************************************************************************************/
- (void) stopListenTo:(SomeClassBox*)object;

/************************************************************************************************************************
*
*	- (void) on:(id)object;
*	This method will be called by listened SomeClassBox if you choose not to use block as a listener
*
*	NOTE: You must override this methos in your subclass and add logic to handle the new value.
*		  Default implementation just does nothing.
*
************************************************************************************************************************/
- (void) on:(id)object;

@end

//=======================================================================================================================
//*	classes managment
//=======================================================================================================================

/************************************************************************************************************************
*
*	IMP class_replaceMethodWithBlock(Class class, SEL originalSelector, id block);
*	replace method of a class with block implementation.
*	If method does not exist will add implementation with block
*
*	parameters:
*			class - a class that will have new method implementation (block)
*			originalSelector - selector of original method (or added selector)
*			id bllck - block with implementation.
*	returns:
*			IMP - implementation of the method.
*
*	NOTE!: id block is a block with return value of the method and first parameters self and SEL. after all parameters of the method
*
************************************************************************************************************************/
IMP class_replaceMethodWithBlock(Class class, SEL originalSelector, id block);


//=======================================================================================================================
//*	NSInvocation category for Block
//=======================================================================================================================

/************************************************************************************************************************
*
*	NSInvocation (block) category
*	Provides additional methods for NSInvocation to work with blocks.
*
************************************************************************************************************************/
//to perform any method or even block on thread you could use invocations and performInvocation methods.
//to get invocation for method use standard way.
//to get invocation from block with variable parameters use this short invocation's category.
@interface NSInvocation (Block)
/************************************************************************************************************************
*
*	+ (instancetype) invocationForBlock:(id) block ,...;
*	Provides invocation for block with parameters.
*	parameters:
*		block - block that we want to have as an invocation
*		... - all blocks parameters value. In order of block's parameter
*
************************************************************************************************************************/
+ (instancetype) invocationForBlock:(id) block ,...;

/************************************************************************************************************************
*
*	+ (instancetype) invocationForBlock:(id) block withParameters:(va_list)valist;
*	Provides invocation for block with parameters.
*	parameters:
*		block - block that we want to have as an invocation
*		va_list - all blocks parameters value. In order of block's parameter
*
************************************************************************************************************************/
+ (instancetype) invocationForBlock:(id) block withParameters:(va_list)valist;
@end

////
// Here is some internal part. No description provided.
////
struct Block_literal_1
{
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1
    {
        unsigned long int reserved;     // NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        // void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        // void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        // const char *signature;                         // IFF (1<<30)
        void* rest[1];
    } *descriptor;
    // imported variables
};

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};
