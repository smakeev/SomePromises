//
//  ImageCashServiceProviderProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 12/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef ImageCashServiceProviderProtocol_h
#define ImageCashServiceProviderProtocol_h

@protocol NetServiceProviderProtocol;

@protocol ImageCashServiceProviderProtocol <NSObject>
- (void) addImage:(UIImage*) image toUrl:(NSString*) imageUrl;
- (UIImage*) imageForUrl:(NSString*) imageUrl;
- (void) clear;
@end
typedef NSObject<ImageCashServiceProviderProtocol> ImagesProvider;
#endif /* ImageCashServiceProviderProtocol_h */
