//
//  SettingBaseViewController.h
//  SomeNews
//
//  Created by Sergey Makeev on 19/10/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN



@interface SettingBaseViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

NS_ASSUME_NONNULL_END
