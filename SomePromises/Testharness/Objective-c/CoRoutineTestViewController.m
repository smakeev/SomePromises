//
//  CoRoutineTestViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 16/04/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

#import "CoRoutineTestViewController.h"
#import "SomePromise.h"

@interface CoRoutineTestViewController ()
{
    SPCoRoutine *coRoutine;
}
@end

@implementation CoRoutineTestViewController

- (IBAction)test1:(id)sender {
    SPGeneratorBuilder *builder1 = [SPGeneratorBuilder createBuilderWithGenerator: ^id(id<SPGeneratorYielder> yielder, NSArray<NSNumber*> *params) {
        for (long i = params[0].integerValue; i <= params[1].integerValue; ++i)
        {
            [yielder yield:@(i)];
        }
        return Void;
    }];
    SPGeneratorBuilder *builder2 = [SPGeneratorBuilder createBuilderWithGenerator: ^id(id<SPGeneratorYielder> yielder, NSArray *params) {
//        [yielder yield:[builder1 build:@[@(0), @(100000)]]];
//        [yielder yield:[builder1 build:@[@(100000), @(900000)]]];
//        [yielder yield:[builder1 build:@[@(10), @(1000000)]]];
        for (long i = 0; i <= 100000000; ++i)
        {
            [yielder yield:@(i)];
        }

        return Void;
    }];

    coRoutine = [[SPCoRoutine alloc] initWithGenerators:@[[builder2 build:nil]] thread: [SomePromiseThread threadWithName:@"CoThread"] step: 3 andRoutine:^(NSNumber *value){
        NSLog(@"!!%@", value);
        return value;
    }];
    [coRoutine run];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
