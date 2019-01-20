//
//  SPFabricTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 30/07/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SPFabricTestViewController.h"
#import "SomePromise.h"

@protocol Entity <NSObject>

@property (nonatomic, readonly, copy) NSString *name;

@end

@interface Cat : NSObject <Entity>
{
   NSString *_name;
   UIColor *_hairColor;
   BOOL _longHair;
}

@property (nonatomic, weak) id<Entity> owner;


- (instancetype) initWithName:(NSString*) name hairColor:(UIColor*)color hairLong:(BOOL)hairLong;

@end

@implementation Cat

- (instancetype) initWithName:(NSString*) name hairColor:(UIColor*)color hairLong:(BOOL)hairLong
{
	self = [super init];
	if(self)
	{
		_name = [name copy];
		_hairColor = color ? [color copy] : [UIColor blackColor];
		_longHair = hairLong;
	}
	return self;
}

- (NSString*) name
{
   return _name;
}

- (BOOL) areHairLong
{
   return _longHair;
}

- (UIColor*) hairColor
{
   return _hairColor;
}

@end

@interface PetOwner : NSObject <Entity>
{
   NSString *_name;
}

@property (nonatomic, strong) id<Entity> pet;

- (instancetype) initWithName:(NSString*) name;

@end

@implementation PetOwner

- (instancetype) initWithName:(NSString*) name
{
	self = [super init];
	if(self)
	{
		_name = [name copy];
	}
	return self;
}

- (NSString*) name
{
   return _name;
}


@end

@interface SPFabricTestModel : NSObject

- (NSString*) getCatName;
- (NSString*) getOwnerNameForCatWithName:(NSString*)catName;

@end

@implementation SPFabricTestModel

- (NSString*) getCatName
{
   sleep(5); //IMITATE REQUEST PROCESSING
   return @"Mutex";
}

- (NSString*) getOwnerNameForCatWithName:(NSString*)catName;
{
	sleep(5); //IMITATE REQUEST PROCESSING
	if([catName isEqualToString:@"Mutex"])
		return @"Sergey";
	return @"Nemo";
}

@end


@interface SPFabricTestViewController ()
{
	SPFabricTestModel *_modelService;
	SPFabric *_fabric;
	
	IBOutlet __weak UILabel *_catName;
	IBOutlet __weak UIView *_catColor;
	IBOutlet __weak UILabel *_hairType;
	IBOutlet __weak UILabel *_ownerName;
}
@end

@implementation SPFabricTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	_modelService = [[SPFabricTestModel alloc] init];
	_fabric = SPFabric.new.registerClass([Cat class], ^(id<SPProducer> p){
		return [[Cat alloc] initWithName:[self->_modelService getCatName] hairColor:p.parameters[@"cat_hair_color"] hairLong:[p.parameters[@"cat_hair_long"] boolValue]];
	}).registerClass([PetOwner class], ^(id<SPProducer> p)
	{
		Cat *cat = p.produce([Cat class]);
		PetOwner *owner = [[PetOwner alloc] initWithName:[self->_modelService getOwnerNameForCatWithName:cat.name]];
		cat.owner = owner;
		owner.pet = cat;
		return owner;
	}).registerParameters(@{@"cat_hair_long" : @(YES)});
	
	_fabric.onProduced = ^(PetOwner *result)
	{
		NSLog(@"%@ has a cat with name %@", result.name, result.pet.name);
	};
}

- (IBAction)pressStartTest:(UIButton*)sender
{
    sender.enabled = NO;
    __weak SPFabricTestViewController *weakSelf = self;
	_fabric.produceOnThreadWithParams([PetOwner class], [SomePromiseThread threadWithName:@"ProducerThread"], @{@"cat_hair_color" : [UIColor grayColor]}).alwaysOnMain(^(Always(result, error))
	{
	    __strong SPFabricTestViewController *strongSelf =  weakSelf;
	    guard(strongSelf) else {return;}
	    PetOwner *owner = (PetOwner*)result;
	    strongSelf->_ownerName.text = owner.name;
	    strongSelf->_catName.text = owner.pet.name;
		Cat *cat = (Cat*)owner.pet;
		strongSelf->_hairType.text = cat.areHairLong ? @"Long hair" : @"Short hair";
		strongSelf->_catColor.backgroundColor = cat.hairColor;
		
		sender.enabled = YES;
	});
}

- (IBAction)uiActivePressed:(id)sender
{
   NSLog(@"UI is active");
}

@end
