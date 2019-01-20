//
//  ContainerableProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 16/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef ContainerableProtocol_h
#define ContainerableProtocol_h

@class UIViewController;
@protocol Containerable <NSObject>

@property (nonatomic, weak) UIViewController<Containerable> *container;
@property (nonatomic, readonly) SPArray<UIViewController<Containerable>*> *embededControllers;
@optional
- (void) getAllAboveContainersForController:(UIViewController<Containerable>*)controller set:(NSMutableSet*)set;
- (void) getAllReceiversForController:(UIViewController<Containerable>*)controller set:(NSMutableSet*)set;

- (UIView*) whereToPresentContainerable;

@end

#endif /* ContainerableProtocol_h */
