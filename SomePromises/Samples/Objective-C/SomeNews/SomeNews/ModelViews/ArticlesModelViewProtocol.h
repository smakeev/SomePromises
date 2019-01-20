//
//  ArticlesModelViewProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 13/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef ArticlesModelViewProtocol_h
#define ArticlesModelViewProtocol_h

@protocol ArticlesModelViewProtocol <NSObject>

@property (atomic, readonly) SPArray *articlesToShow;
@property (atomic, readonly) SPArray *articlesToShowBySources;

@property (nonatomic, readonly) SomeClassBox<NSNumber*> *downloadingNewPage;//BOOL

@end


#endif /* ArticlesModelViewProtocol_h */
