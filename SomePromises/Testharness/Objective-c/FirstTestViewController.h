//
//  FirstTestViewController.h
//  SomePromises
//
//  Created by Sergey Makeev on 12/01/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstTestViewController : UIViewController

- (IBAction)startPromise:(id)sender;
- (IBAction)startRejectedPromise:(id)sender;
- (IBAction)startPromiseWithDelegate:(id)sender;
- (IBAction)startRejectedPromiseWithDelegate:(id)sender;
- (IBAction)startPospondedPromise:(id)sender;
- (IBAction)startPostpondedRejectedPromise:(id)sender;
- (IBAction)startPostpondedPromiseWithDelegate:(id)sender;
- (IBAction)startPostpondedRejectedPromiseWithDelegate:(id)sender;

- (IBAction)startMethodTest:(id)sender;

@end
