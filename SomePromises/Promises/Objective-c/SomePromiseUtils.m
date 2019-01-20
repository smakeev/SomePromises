//
//  SomePromiseUtils.m
//  SomePromises
//
//  Created by Sergey Makeev on 26/04/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SomePromiseUtils.h"
#import "SomePromiseTypes.h"
#import "SomePromiseInternals.h"
#import <objc/runtime.h>

BLOCK_SIGNATURE_AVAILABLE

static DeferPools *_deferpools = nil;

@interface DeferPool1Pair: NSObject
{
   NSNumber *_number;
   Defer *_defer;
}

@property (nonatomic, readonly) NSNumber *number;
@property (nonatomic, readonly) Defer *defer;

- (instancetype) initWithNumber:(NSNumber*)number code:(Defer*)defer;

@end

@implementation DeferPool1Pair

- (instancetype) initWithNumber:(NSNumber*)number code:(Defer*)defer
{
    self = [super init];
	
    if(self)
    {
	   _number = number;
	   _defer = defer;
	}
	
	return self;
}

@end

@interface DeferPools ()
{
   NSMutableDictionary<NSString*, NSMutableArray<DeferPool1Pair*>*> *_deferPool1;
   NSMapTable<NSString*, NSMutableDictionary<NSNumber*, DeferBlock>*> *_deferPool2;
   const NSLock *_somePromiseDeferLocker;
}

@property(nonatomic, readonly)NSMutableDictionary<NSString*, NSMutableArray<DeferPool1Pair*>*> *deferPool1;
@property(nonatomic, readonly)NSMapTable<NSString*, NSMutableDictionary<NSNumber*, DeferBlock>*> *deferPool2;

@end

@implementation DeferPools

+ (instancetype) instance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
	{
	    _deferpools = [[DeferPools alloc] init];
	});
	
	return _deferpools;
}

- (instancetype) init
{
   self = [super init];
   if (self)
   {
       _deferPool1 = [NSMutableDictionary new];
	   _deferPool2 = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
	   _somePromiseDeferLocker = [[NSLock alloc] init];
   }
	
   return self;
}

@end

@interface Defer (internal)
- (void) removeBlock;
@end

BOOL areThereBlocksForTagWithName(NSString *tagName)
{
	return [[DeferPools instance].deferPool1 objectForKey:tagName] ? YES : NO;
}

void addAllBlocksToTagForTagWithName(id deferTag, NSString *tagName)
{
    NSMutableDictionary *deferDict = (NSMutableDictionary*) deferTag;
	NSMutableArray<DeferPool1Pair*> *allPairs = [[DeferPools instance].deferPool1 objectForKey:tagName];
	for(DeferPool1Pair *pair in allPairs)
	{
		[deferDict setObject:pair.defer forKey:pair.number];
	}
	[[DeferPools instance].deferPool1 removeObjectForKey:tagName];
}

void storeTag(id deferTag, NSString *tagName)
{
   NSMutableDictionary *deferDict = (NSMutableDictionary*) deferTag;
   [[DeferPools instance].deferPool2 setObject:deferDict forKey:tagName];
}

id getDeferTagByName(NSString *tagName)
{
	return [[DeferPools instance].deferPool2 objectForKey:tagName];
}

void addBlockToTagWithNumber(id tag, int number, DeferBlock block)
{
    NSMutableDictionary *deferDict = (NSMutableDictionary*) tag;
    [deferDict setObject:[Defer block:block] forKey:@(number)];
}

void addBlockToPoolWithTagName(int number, DeferBlock block, NSString *tagName)
{
    NSMutableArray<DeferPool1Pair*> *allPairs = [[DeferPools instance].deferPool1 objectForKey:tagName];
    if (allPairs == nil)
    {
       allPairs = [NSMutableArray new];
	   [[DeferPools instance].deferPool1 setObject:allPairs forKey:tagName];
	}
	
	DeferPool1Pair *pair = [[DeferPool1Pair alloc] initWithNumber:@(number) code:[Defer block:block]];
	[allPairs addObject:pair];
}

@implementation Defer {
   @private void(^_deferBlock)(void);
}

+ (instancetype)block:(void (^)(void))block {
   Defer *_d = [Defer new];
   _d->_deferBlock = block ?: ^{};
   return _d;
}
- (void)dealloc {
   _deferBlock();
}

- (void) doNothing {}

- (void) removeBlock
{
   _deferBlock = ^{};
}

@end

#define OBJC_SELECTOR(a, i) [[OBJC_SELECTOR alloc] initWithSelector:a number:i]
#define RAW_SELECTOR(a) a.mySelector 

static BOOL protocolHasMethod(Protocol *protocol, SEL selector, BOOL isRequiredMethod, BOOL isInstanceMethod)
{
	struct objc_method_description protDesc = protocol_getMethodDescription(protocol, selector, isRequiredMethod, isInstanceMethod);
	if(protDesc.name == NULL && protDesc.types == NULL)
	{
		// Method not defined in the protocol
		return NO;
	}
	
	return YES;
}

@interface OBJC_SELECTOR : NSObject

@property (nonatomic, assign) SEL mySelector;
@property (nonatomic, assign) int i;

@end

@implementation OBJC_SELECTOR

- (instancetype) initWithSelector:(SEL)selector number:(int)number
{
   self = [super init];
	
   if(self)
   {
      self.mySelector = selector;
      self.i = number;
   }
	
   return self;
}

@end

@implementation SomePromiseUtils

+ (NSError*) errorFromException:(NSException*)exception
{
		   NSMutableDictionary * info = [NSMutableDictionary dictionary];
           [info setValue:exception.name forKey:@"ExceptionName"];
           [info setValue:exception.reason forKey:@"ExceptionReason"];
           [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
		   [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
           [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];

           return [[NSError alloc] initWithDomain:@"com.someprojects.somepromises" code:ESomePromiseError_FromException userInfo:info];
}

+ (BOOL) protocol:(Protocol*)protocol hasRequiredInstanceMethodWithselector:(SEL)selector
{
	return protocolHasMethod(protocol, selector, YES, YES);
}

+ (BOOL) protocol:(Protocol*)protocol hasRequiredClassMethodWithselector:(SEL)selector
{
	return protocolHasMethod(protocol, selector, YES, NO);

}

+ (BOOL) protocol:(Protocol*)protocol hasOptionalInstanceMethodWithselector:(SEL)selector
{
	return protocolHasMethod(protocol, selector, NO, YES);

}

+ (BOOL) protocol:(Protocol*)protocol hasOptionalClassMethodWithselector:(SEL)selector
{
	return protocolHasMethod(protocol, selector, NO, NO);

}

+ (BOOL) protocol:(Protocol*)protocol hasMethodWithSelector:(SEL)selector
{
   return protocolHasMethod(protocol, selector, YES, YES) || protocolHasMethod(protocol, selector, NO, YES) || protocolHasMethod(protocol, selector, YES, NO) || protocolHasMethod(protocol, selector, NO, NO);
	
}

+ (BOOL) class:(Class)class hasMethod:(SEL)selector
{
   unsigned int mc = 0;
   Method *mlist = class_copyMethodList(class, &mc);
   for(int i = 0; i < mc; i++)
   {
      SEL class_selector = method_getName(mlist[i]);
      if (sel_isEqual(selector, class_selector))
		return YES;
   }
   return NO;
}

+ (void) makeProtocolOriented:(Class)class protocol:(Protocol*) protocol extention:(Class)extentionClass whereSelf:(Protocol*) selfRestrictions
{
   //Check if everything right
	
   if(![class conformsToProtocol:protocol])
   {
     NSLog(@"Some Promises ERROR: makeProtocol oriented, class doesnot conform to the prtocol");
     return;
   }
	
   if(![extentionClass conformsToProtocol:protocol])
   {
     NSLog(@"Some Promises ERROR: makeProtocol oriented, extentionClass doesnot conform to the prtocol");
     return;
   }

   if(![class conformsToProtocol:selfRestrictions])
   {
     NSLog(@"Some Promises ERROR: makeProtocol oriented, class doesnot conform to the selfRestrictions");
     return;
   }

   //2 take all selectors from extenson
   unsigned int mc = 0;
   NSMutableArray *selectors = [NSMutableArray new];
	
   Method *mlist = class_copyMethodList(extentionClass, &mc);
   for(int i = 0; i < mc; i++)
   {
      SEL selector = method_getName(mlist[i]);
	  if(![SomePromiseUtils protocol:protocol  hasMethodWithSelector:selector])
	  {
	     continue; //if protocol does not contain this selector, ignore it.
	  }
	  
      if(![SomePromiseUtils class:class hasMethod:selector]) //not to owerride methods that class has implemented itself
      {
         [selectors addObject:OBJC_SELECTOR(selector, i)];
	  }
   }
	
   //3 add methods to class
	
   for (OBJC_SELECTOR *selector in selectors)
   {
      SEL selectorToBeAdded = RAW_SELECTOR(selector);
      Method methodToBeAdded = mlist[selector.i];
      BOOL didAddMethod = class_addMethod(class, selectorToBeAdded, method_getImplementation(methodToBeAdded), method_getTypeEncoding(methodToBeAdded));
	  if(!didAddMethod)
	  {
	     NSLog(@"Some Promises WARNING: method %s can't be added", sel_getName(selectorToBeAdded));
	  }
   }
}

+ (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return (__bridge_transfer NSString *)uuidStringRef;
}

@end

@interface SomeClassBox()
{
   NSMapTable<id, NSMutableArray<SPListener> *> *_listeners;
   NSMapTable<id, NSMutableArray<SPListener> *> *_onceListeners;
}
@end

@implementation SomeClassBox

@synthesize value = _value;

+ (instancetype)empty
{
   return [[SomeClassBox alloc] initEmpty];
}

- (instancetype) init
{
	return [self initEmpty];
}

- (instancetype) initEmpty
{
   self = [super init];
   if(self)
   {
	   self.value = nil;
	   _listeners = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
	   _onceListeners = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
   }
   return self;
}

- (instancetype) initWithValue:(id) value
{
   self = [super init];
   if(self)
   {
		 self.value = value;
		 _listeners = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
		 _onceListeners = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
	 }
	
	 return self;
}


- (void) skip
{
	@synchronized(self)
	{
		_value = nil;
		//don't call any odservers
	}
}

- (void) skipValue:(id)value
{
	@synchronized(self)
	{
		_value = value;
		//don't call any odservers
	}
}

- (void) setValue:(id)value
{
	@synchronized(self)
	{
		_value = value;
       [self callListenersForward];
	}
}

- (void) addObject:(id) object listener:(SPListener) listener
{
   @synchronized(self)
   {
		NSMutableArray<SPListener> *listeners = [_listeners objectForKey:object];
		guard(listeners) else {listeners = [NSMutableArray new];}
		[listeners addObject:[listener copy]];
		[_listeners setObject:listeners forKey:object];
   }
}

- (void) addOnceObject:(id) object listener:(SPListener) listener
{
   @synchronized(self)
   {
		NSMutableArray<SPListener> *listeners = [_onceListeners objectForKey:object];
		guard(listeners) else {listeners = [NSMutableArray new];}
		[listeners addObject:[listener copy]];
		[_onceListeners setObject:listeners forKey:object];
   }
}

- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bind;
{
    __weak SomeClassBox *weakSelf = self;
    return [^void(id listener, SPListener listenerBlock)
           {
			 __strong SomeClassBox *strongSelf = weakSelf;
			 if(strongSelf)
			 {
			    [strongSelf addObject:listener listener:[listenerBlock copy]];
				listenerBlock(strongSelf.value);
			 }
		   } copy];
}

- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bindNext
{
    __weak SomeClassBox *weakSelf = self;
	return [^void(id listener, SPListener listenerBlock)
			{
					__strong SomeClassBox *strongSelf = weakSelf;
					if(strongSelf)
					{
						[strongSelf addObject:listener listener:[listenerBlock copy]];
					}
			} copy];
}

- (void (^ __nonnull)(id _Nonnull, SPListener _Nullable))bindOnce
{
    __weak SomeClassBox *weakSelf = self;
	return [^void(id listener, SPListener listenerBlock)
			{
					__strong SomeClassBox *strongSelf = weakSelf;
					if(strongSelf)
					{
						[strongSelf addOnceObject:listener listener:[listenerBlock copy]];
					}
			} copy];
}

- (void) bind:(id)target listener:(SPListener)listener
{
 	[self addObject:target listener:[listener copy]];
	listener(self.value);
}

- (void) bindNext:(id)target listener:(SPListener)listener
{
 	[self addObject:target listener:[listener copy]];
}

- (void) bindOnce:(id)target listener:(SPListener)listener
{
	[self addOnceObject:target listener:[listener copy]];
}

- (void) unbind:(id)object
{
   @synchronized(self)
   {
      [_listeners removeObjectForKey:object];
      [_onceListeners removeObjectForKey:object];
   }
}

- (void (^ __nonnull)(id _Nonnull))unbind
{
	__weak SomeClassBox *weakSelf = self;
    return [^void(id listener)
    {
		__strong SomeClassBox *strongSelf = weakSelf;
		if(strongSelf)
		{
			[strongSelf unbind:listener];
		}
	} copy];
}

- (void) unbindAll
{
	@synchronized(self)
	{
		[_listeners removeAllObjects];
		[_onceListeners removeAllObjects];
	}
}

- (void) callListenersForward
{
	@synchronized(self)
	{
		for(id listenerBlockKey in _listeners)
		{
		    NSArray *listeners = [_listeners objectForKey:listenerBlockKey];
			for(SPListener listener in listeners)
			{
				listener(_value);
			}
		}
		for(id listenerBlockKey in _onceListeners)
		{
			NSArray *listeners = [_onceListeners objectForKey:listenerBlockKey];
			for(SPListener listener in listeners)
			{
				listener(_value);
			}
		}
		[_onceListeners removeAllObjects];
	}
}

@end

@interface SomeListener()
{
    void (^_block)(id _Nullable);
}
@end

@implementation SomeListener

- (instancetype) init
{
   if(self = [super init])
   {
	  __weak SomeListener *weakSelf = self;
      _block = [^(id object)
      {
         __strong SomeListener *strongSelf = weakSelf;
		 [strongSelf on:object];
	  } copy];
   }
   return self;
}

- (instancetype) initWithBlock:(void (^)(id _Nullable))listener
{
   if(self = [super init])
   {
      _block = [listener copy];
   }
   return self;
}

- (void) listenTo:(SomeClassBox*)object
{
    object.bind(self, _block);
}

- (void) listenNextTo:(SomeClassBox*)object
{
   object.bindNext(self, _block);
}

- (void) listenOnce:(SomeClassBox*)object
{
	object.bindOnce(self, _block);
}

- (void) stopListenTo:(SomeClassBox*)object
{
    [object unbind:self];
}

- (void) on:(id)object
{
   //owerride this method.
}

@end

@implementation NSInvocation (Block)

+ (instancetype) invocationWithBlock:(id) block
{
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:__BlockSignature__(block)]];
    invocation.target = block;
    return invocation;
}

#define ARG_GET_SET(type) do {type val = 0; val = va_arg(args,type); [invocation setArgument:&val atIndex:1 + i];} while (0)
+ (instancetype) invocationForBlock:(id) block ,...
{
    va_list args;
    va_start(args, block);
    NSInvocation* invocation = [NSInvocation invocationForBlock: block withParameters: args];
    va_end(args);
    return invocation;
}

+ (instancetype) invocationForBlock:(id) block withParameters:(va_list)args
{
    NSInvocation* invocation = [NSInvocation invocationWithBlock:block];
    NSUInteger argsCount = invocation.methodSignature.numberOfArguments - 1;

    for(NSUInteger i = 0; i < argsCount ; ++i){
        const char* argType = [invocation.methodSignature getArgumentTypeAtIndex:i + 1];
        if (argType[0] == _C_CONST) argType++;

        if (argType[0] == '@') {                                //id and block
            ARG_GET_SET(id);
        }else if (strcmp(argType, @encode(Class)) == 0 ){       //Class
            ARG_GET_SET(Class);
        }else if (strcmp(argType, @encode(IMP)) == 0 ){         //IMP
            ARG_GET_SET(IMP);
        }else if (strcmp(argType, @encode(SEL)) == 0) {         //SEL
            ARG_GET_SET(SEL);
        }else if (strcmp(argType, @encode(double)) == 0){       //
            ARG_GET_SET(double);
        }else if (strcmp(argType, @encode(float)) == 0){
            float val = 0;
            val = (float)va_arg(args,double);
            [invocation setArgument:&val atIndex:1 + i];
        }else if (argType[0] == '^'){                           //pointer ( andconst pointer)
            ARG_GET_SET(void*);
        }else if (strcmp(argType, @encode(char *)) == 0) {      //char* (and const char*)
            ARG_GET_SET(char *);
        }else if (strcmp(argType, @encode(unsigned long)) == 0) {
            ARG_GET_SET(unsigned long);
        }else if (strcmp(argType, @encode(unsigned long long)) == 0) {
            ARG_GET_SET(unsigned long long);
        }else if (strcmp(argType, @encode(long)) == 0) {
            ARG_GET_SET(long);
        }else if (strcmp(argType, @encode(long long)) == 0) {
            ARG_GET_SET(long long);
        }else if (strcmp(argType, @encode(int)) == 0) {
            ARG_GET_SET(int);
        }else if (strcmp(argType, @encode(unsigned int)) == 0) {
            ARG_GET_SET(unsigned int);
        }else if (strcmp(argType, @encode(BOOL)) == 0 || strcmp(argType, @encode(bool)) == 0
                  || strcmp(argType, @encode(char)) == 0 || strcmp(argType, @encode(unsigned char)) == 0
                  || strcmp(argType, @encode(short)) == 0 || strcmp(argType, @encode(unsigned short)) == 0) {
            ARG_GET_SET(int);
        }else{                  //struct union and array
            assert(false && "struct union array unsupported!");
        }
    }

    return invocation;
}

@end

IMP class_replaceMethodWithBlock(Class class, SEL originalSelector, id block)
{
    IMP newImplementation = imp_implementationWithBlock(block);
	
    Method method = class_getInstanceMethod(class, originalSelector);
    return class_replaceMethod(class, originalSelector, newImplementation, method_getTypeEncoding(method));
}

NSError* rejectionErrorWithText(NSString* description, NSInteger code)
{
   if (description == nil)
   {
     description = @"";
   }
   return [NSError errorWithDomain:@"com.someprojects.somepromises" code:code userInfo:@{@"Error reason": description}];
}
