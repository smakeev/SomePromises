//
//  ArticlesModelView.h
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticlesModelViewProtocol.h"

@class ArticlesModel;
@interface ArticlesModelView : NSObject <ArticlesModelViewProtocol>

- (instancetype) initWithModel:(ArticlesModel*)articles;

@end
