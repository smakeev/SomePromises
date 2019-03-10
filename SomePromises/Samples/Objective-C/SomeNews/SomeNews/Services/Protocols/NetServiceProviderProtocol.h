//
//  NetServiceProviderProtocol.h
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#ifndef NetServiceProviderProtocol_h
#define NetServiceProviderProtocol_h

@protocol NetServiceProviderProtocol <NSObject>

- (SomePromise*) getTopNews;
- (void) openInSafariURL:(NSURL*)url;
- (SomePromise*) predownloadPagesJson:(NSInteger) pagesToDownload;
- (void) addPage:(SPPair*)pairWhithPage usingChain:(SomePromise*)chain;
- (SomePromise*) getSources;

@end
typedef NSObject<NetServiceProviderProtocol> NetProvider;


#endif /* NetServiceProviderProtocol_h */
