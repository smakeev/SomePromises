//
//  SomePromiseLocContainer.h
//  SomePromises
//
//  Created by Sergey Makeev on 29/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
////////////////////////////////////////////////////////////////////////////////////////
//
//	class SPFabric
//	Provides standard loc container.
//
//NOTE!: Is not thread safe.
//
//	You may create a fabric wich will be responsable for
//	creating an object with particular properties and values.
//
//	Just register the class in the fabric and register all classes
//	and values it will need.
//
//	Also allows to make object creation process on separate thread using future (SomePromiseFuture)
//	This also means it could be a start point for some promise chain.
//
//	NOTE!: It is probably closer to builder pattern than to the fabric.
//
//	NOTE!: Not threadsafe.
//////////////////////////////////////////////////////////////////////////////////////

@class SomePromiseThread;
@class SomePromiseFuture;
@class SPFabric;

//SPProducer protocol.
//protocol for the object creator.
//This protocol will be used as a parameter inside producing block.
@protocol SPProducer <NSObject>

//parameters and it's values be added to the class on creation moment.
//They are not automatically used (by KVO or other "magic").
//Just you could use them inside producing block to provide inside producing class
//inside init methods, properties or by calling some method of the created class instance.
@property (nonatomic, readonly) NSDictionary<NSString*, id> *parameters;

//return an instance of the class by calling producing block associated with this className.
- (id) produce:(Class _Nonnull)className;

//return a block returning an instance of the class by calling producing block associated with this className.
//block is copied in heap.
- (id _Nonnull (^ __nonnull)(Class _Nonnull className))produce;

@end

typedef NSObject<SPProducer> SPProducer;

//ProducingBlock is a block to be registered with class name to be called by producer
//to create an instance of the object.
typedef id (^ProducingBlock)(id<SPProducer>);

//OnProduced is a block to be called as a handler of producing finish.
//parameter is an instance of produced object.
typedef void (^OnProduced)(id result);

@interface SPFabric : NSObject

//handler for produced object. Will be called at the end of the procecc wiht the final result.
@property (nonatomic, copy)OnProduced onProduced;

//create new empty producer (no class registered yet).
+ (instancetype) new;

//produce an instance of a class.
- (id) produce:(Class _Nonnull)className;

//produce an instance of a class with parameters.
//parameters will not be added as a producer parameters on the next call.
//NOTE!: parameters provided here will replace parameters inside the producer.
//	If producer had parameters with the same name.
//	If producer had not parameters with that names
//	it means they will be probaly ignored due to producing blocks probably don't use them.
//NOTE!:	If producing block uses parameters wich are not registerd than you always have to call
//- (id) produce:(Class _Nonnull)className withParams:(NSDictionary *_Nullable) params
- (id) produce:(Class _Nonnull)className withParams:(NSDictionary *_Nullable) params;

//produce an instance of a class on provided thread
//method returns SomePromiseFuture instead of the ready instance.
//Future will be resolved with produced instance.
//You can add promises to the future starting one or several chains.
//Also you can use onProduced block to get the producing result.
//And you can work with future as it is a produced instance.
//All calls will be done later. See SomePromiseFuture for more details.
- (SomePromiseFuture *_Nonnull) produce:(Class _Nonnull)className onThread:(SomePromiseThread *_Nullable) thread;

//produce an instance of a class on provided queue
//method returns SomePromiseFuture instead of the ready instance.
//Future will be resolved with produced instance.
//You can add promises to the future starting one or several chains.
//Also you can use onProduced block to get the producing result.
//And you can work with future as it is a produced instance.
//All calls will be done later. See SomePromiseFuture for more details.
- (SomePromiseFuture *_Nonnull) produce:(Class _Nonnull)className onQueue:(dispatch_queue_t _Nullable) queue;

//produce an instance of a class on provided thread
//method returns SomePromiseFuture instead of the ready instance.
//Future will be resolved with produced instance.
//You can add promises to the future starting one or several chains.
//Also you can use onProduced block to get the producing result.
//And you can work with future as it is a produced instance.
//All calls will be done later. See SomePromiseFuture for more details.
//Parameters will not be added as a producer parameters on the next call.
//NOTE!: parameters provided here will replace parameters inside the producer.
//	If producer had parameters with the same name.
//	If producer had not parameters with that names
//	it means they will be probaly ignored due to producing blocks probably don't use them.
//NOTE!:	If producing block uses parameters wich are not registerd than you always have to call
// prodicing method with parameters.
- (SomePromiseFuture *_Nonnull) produce:(Class _Nonnull)className  withParams:(NSDictionary *_Nullable) params onThread:(SomePromiseThread *_Nullable) thread;

//produce an instance of a class on provided queue
//method returns SomePromiseFuture instead of the ready instance.
//Future will be resolved with produced instance.
//You can add promises to the future starting one or several chains.
//Also you can use onProduced block to get the producing result.
//And you can work with future as it is a produced instance.
//All calls will be done later. See SomePromiseFuture for more details.
//Parameters will not be added as a producer parameters on the next call.
//NOTE!: parameters provided here will replace parameters inside the producer.
//	If producer had parameters with the same name.
//	If producer had not parameters with that names
//	it means they will be probaly ignored due to producing blocks probably don't use them.
//NOTE!:	If producing block uses parameters wich are not registerd than you always have to call
// prodicing method with parameters.
- (SomePromiseFuture *_Nonnull) produce:(Class _Nonnull)className withParams:(NSDictionary *_Nullable) params onQueue:(dispatch_queue_t _Nullable) queue;

//Bind a class with producing block inside this producer.
//It means on call produce for this (registered) class producer will call this provided block.
- (instancetype _Nonnull) register:(Class _Nonnull)className producingBlock:(ProducingBlock _Nonnull)block;

//register parameters to be used inside producing blocks.
- (instancetype _Nonnull) registerParameters:(NSDictionary *_Nullable)params;


//Methods returning blocks providing above methods.
- (id _Nonnull (^ __nonnull)(Class _Nonnull className))produce;
- (id _Nonnull (^ __nonnull)(Class _Nonnull className, NSDictionary *_Nullable params))produceWithParams;
- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, SomePromiseThread *_Nullable thread))produceOnThread;
- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, dispatch_queue_t _Nullable queue))produceOnQueue;
- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, SomePromiseThread *_Nullable thread, NSDictionary *_Nullable params))produceOnThreadWithParams;
- (SomePromiseFuture *_Nonnull(^ __nonnull)(Class _Nonnull className, dispatch_queue_t _Nullable queue, NSDictionary *_Nullable params))produceOnThreadWithQueue;
- (SPFabric *_Nonnull (^ __nonnull)(Class _Nonnull className, ProducingBlock _Nonnull producingBlock))registerClass;
- (SPFabric *_Nonnull (^ __nonnull)(NSDictionary *_Nullable params))registerParameters;


@end

