//
//  AlertsPresenterProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 14/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef AlertsPresenterProtocol_h
#define AlertsPresenterProtocol_h

@protocol AlertsPresenterProtocol <NSObject>

@required
@property (nonatomic, readonly) UIView *baseAlertView;

@optional
@property (nonatomic, readonly) UIView *whereToPresent;

- (void) showBaseAlertWithData:(NSDictionary*)data;
- (void) showAlertViewWithContentView:(UIView*(^ _Nullable)(CGSize desiredSize)) contentCreatorBlock;
- (void) hideAlertView:(UITapGestureRecognizer*)sender;

@end

#endif /* AlertsPresenterProtocol_h */
