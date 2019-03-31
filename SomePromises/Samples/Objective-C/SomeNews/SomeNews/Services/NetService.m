//
//  NetService.m
//  SomeNews
//
//  Created by Sergey Makeev on 11/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NetService.h"
#import "Constants.h"
#import "ServicesProvider.h"
#import "UserServiceProviderProtocol.h"

@interface NetService ()
{
	SomePromiseThread *_thread;
}
@end

@implementation NetService

- (instancetype) init
{
	self = [super init];
	if (self)
	{
		_thread = [SomePromiseThread threadWithName:@"Network Downloding Promises Thread"];
	}
	return self;
}

- (SomePromise*) getTopNews
{
	SomePromise *promise = [SomePromise promiseWithName:@"starterPromise" value:@(0) class:nil];
	return [self promiseThenTo:promise forPage:0];
}


- (void) openInSafariURL:(NSURL*)url
{
	[[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @(NO)} completionHandler:nil];
}

- (SomePromise*) getSources
{
	return (SomePromise*)spTry(^(SomeParameterProvider *self,  SomeIsRejectedBlockProvider *isRejected){
		NetService *service = self.weakValue;
		NSURL *url = [[NSURL URLWithString:mainURL] URLByAppendingPathComponent:@"sources"];
		NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
		urlComponents.scheme = @"https";
			NSURLQueryItem *countryURLQueryItem = [NSURLQueryItem queryItemWithName:@"country" value:[service->_owner.user getCountry]];
		NSURLQueryItem *languageURLQueryItem = [NSURLQueryItem queryItemWithName:@"language" value:[service->_owner.user getLanguage]];
		NSURLQueryItem *categoryURLQueryItem =  [NSURLQueryItem queryItemWithName:@"category" value:[service->_owner.user getCategory]];
		urlComponents.queryItems = 	[SPArray fromArray:@[countryURLQueryItem, languageURLQueryItem, categoryURLQueryItem]].filter(^(NSURLQueryItem *item){
			return (BOOL)(item.value != nil);
		}).toArray;
		NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
		[sessionConfiguration setHTTPAdditionalHeaders:@{@"Accept" : @"application/json", @"X-Api-Key" : apiKey}];
		sessionConfiguration.timeoutIntervalForRequest = 30.0;
		sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
		NSURLSession *session = nil;
		
		session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
		
		NSURLSessionDataTask *getTask = nil;
		__block NSData *resultData = nil;
		__block NSURLResponse *resultResponse = nil;
		__block NSError *resultError = nil;
		__block BOOL finished = NO;
		@sp_avoidblockretain(service)
		getTask = [session dataTaskWithURL:urlComponents.URL completionHandler:^(NSData *data,
																		NSURLResponse *response,
																		NSError *error)
		{
			@sp_strongify(service)
			resultData = data;
			resultResponse = response;
			resultError = error;
			if(error)
			{
				NSLog(@"§§§ Downloading error");
			}
			@synchronized(service)
			{
				finished = YES;
			}
		}];
		
		@sp_avoidend(service)
		[getTask resume];
		BOOL isFinished = NO;
		@synchronized(service)
		{
			isFinished = finished;
		}
		while(!isFinished)
		{
			if(isRejected.isRejectedBlock())
			{
				[getTask cancel];
				@throw (nil); //just exit the promise block.
			}
			@synchronized(service)
			{
				isFinished = finished;
			}
		}
		NSString *fullResult = nil;
		NSError *error = nil;
		@try
		{
			fullResult = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingAllowFragments error:&error];
			if (error) {
				@throw [NSException exceptionWithName:@"JSON parsing error" reason:@"Response has a wrong format" userInfo:@{@"error": error}];
			}
		}
		@catch(NSException *e)
		{
			@throw(e);
		}
		return fullResult;
	}, weakParameterProvider(self), isRejectedProvider());
}

- (SomePromise*) promiseThenTo:(SomePromise*)promise forPage:(NSInteger) page
{
	return (SomePromise*)promise.spThen(^(NSString *promiseName, SomeParameterProvider *self, SomeParameterProvider *pageParameter, SomeIsRejectedBlockProvider *isRejected){
		//don't show network indication for predownloading.
		NetService *service = self.weakValue;
		
		__block BOOL finished = NO;
		NSInteger page = [pageParameter.value integerValue];
		NSURL *url = [[NSURL URLWithString:mainURL] URLByAppendingPathComponent:@"top-headlines"];
		NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
		urlComponents.scheme = @"https";
		
		NSString *source = [service->_owner.user getSource];
		if (source && [source length]) {
			NSURLQueryItem *sourceItem = [NSURLQueryItem queryItemWithName:@"sources" value:source];
			NSURLQueryItem *queryURLQueryItem = [NSURLQueryItem queryItemWithName:@"q" value:service->_owner.user.querry];
			urlComponents.queryItems = [SPArray fromArray:@[sourceItem, queryURLQueryItem]].filter(^(NSURLQueryItem *item) {
				return (BOOL)(item.value != nil);
			}).toArray;
		} else {
			NSURLQueryItem *countryURLQueryItem = [NSURLQueryItem queryItemWithName:@"country" value:[service->_owner.user getCountry]];
			NSURLQueryItem *languageURLQueryItem = [NSURLQueryItem queryItemWithName:@"language" value:[service->_owner.user getLanguage]];
			NSURLQueryItem *categoryURLQueryItem =  [NSURLQueryItem queryItemWithName:@"category" value:[service->_owner.user getCategory]];
			NSURLQueryItem *queryURLQueryItem = [NSURLQueryItem queryItemWithName:@"q" value:service->_owner.user.querry];
			NSURLQueryItem *pageSizeURLQueryItem = [NSURLQueryItem queryItemWithName:@"pageSize" value:[service->_owner.user pageSize]];
			NSURLQueryItem *pageNumberURLQueryItem = [NSURLQueryItem queryItemWithName:@"page" value: page ? [NSString stringWithFormat: @"%ld", (long)page] : nil];
		
			urlComponents.queryItems = 	[SPArray fromArray:@[countryURLQueryItem, languageURLQueryItem, categoryURLQueryItem, queryURLQueryItem, pageNumberURLQueryItem, pageSizeURLQueryItem]].filter(^(NSURLQueryItem *item){
			return (BOOL)(item.value != nil);
			}).toArray;
		}
		
		NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
		[sessionConfiguration setHTTPAdditionalHeaders:@{@"Accept" : @"application/json", @"X-Api-Key" : apiKey}];
		sessionConfiguration.timeoutIntervalForRequest = 30.0;
		sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
		NSURLSession *session = nil;
		
		@sp_avoidblockretain(service)
		session = [NSURLSession sessionWithConfiguration:sessionConfiguration
												delegate:
				   [SomePromiseObject createObjectBasedOn:[NSObject class]
												protocols:@[@protocol(NSURLSessionDelegate)]
										   bindLifetimeTo:nil//sessionDelegateLifeAnchor
											   definition:^(SomePromiseObject* creator) {
												   @sp_strongify(service)
												   [creator create:@selector(URLSession:didBecomeInvalidWithError:)
																with:^(id sessionDelegate, NSURLSession *session, NSError *error){
																	@sp_strongify(service)
																	@synchronized(service)
																	{
																		finished = YES;
																	}
																}];
													[creator addDealloc:^{
														NSLog(@"NSURLSession delegate deallocated");
													
											   		}];
												}]
										   delegateQueue:nil];
		@sp_avoidend(service)
		
		__block NSData *resultData = nil;
		__block NSURLResponse *resultResponse = nil;
		__block NSError *resultError = nil;

		NSURLSessionDataTask *getTask = nil;
		@sp_avoidblockretain(service)
		getTask = [session dataTaskWithURL:urlComponents.URL completionHandler:^(NSData *data,
																		NSURLResponse *response,
																		NSError *error)
		{
			@sp_strongify(service)
			resultData = data;
			resultResponse = response;
			resultError = error;
			if(error)
			{
				NSLog(@"§§§ Downloading error");
			}
			@synchronized(service)
			{
				finished = YES;
			}
		}];
		@sp_avoidend(service)
		
		[getTask resume];
		BOOL isFinished = NO;
		@synchronized(service)
		{
			isFinished = finished;
		}
		while(!isFinished)
		{
			if(isRejected.isRejectedBlock())
			{
				[getTask cancel];
				@throw (nil); //just exit the promise block.
			}
			@synchronized(service)
			{
				isFinished = finished;
			}
		}
		//Usually you should keep a session for the next request.
		//Here we do invalidating to demonstrate delegate deallocation.
		[session finishTasksAndInvalidate];
		guard(!resultError) else { @throw([NSException exceptionWithName:@"GET error" reason:@"URL session got error" userInfo:@{@"error": resultError}]);}
		
		NSError *error;
		NSDictionary *fullResult;
		@try
		{
			fullResult = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingAllowFragments error:&error];
		}
		@catch(NSException *e)
		{
			@throw(e);
		}
		
		guard([fullResult[@"status"] isEqualToString:@"ok"]) else
		{
			if (error)
			{
				@throw([NSException exceptionWithName:@"JSON parsing error" reason:@"Response has a wrong format" userInfo:@{@"error": error}]);
			}
		
			if ([fullResult[@"status"] isEqualToString:@"error"])
			{
				NSLog(@"#### ERROR");
				//@TODO: create error by response
			}
			else
			{
				NSLog(@"#### ERROR");
				//@TODO: general error
			}
		}
		
		NSArray *articles = fullResult[@"articles"];
		//activate image cash
		NSLog(@"!!!!!!!!! Total results:%@", fullResult[@"totalResults"]);
		
		SPPair *result = [SPPair pairWithLeft:fullResult[@"totalResults"] right:articles];
		return result;
		
	}, topNewsPromise, weakParameterProvider(self), parameterProvider(@(page)), isRejectedProvider());
}

- (SomePromise*) predownloadPagesJson:(NSInteger) pagesToDownload
{
	//configurating promises.
	//using predefined start promise
	SomePromise *promise = [SomePromise promiseWithName:@"starterPromise" value:@(0) class:nil];
	NSInteger havePages = pagesToDownload;
	NSInteger currentPage = 1;
	while(havePages)
	{
		promise = [self promiseThenTo:promise forPage:currentPage++];
		havePages--;
	}
	
	return promise;
}

- (void) addPage:(SPPair<NSNumber*, SPArrayElementWrapper*>*)pairWhithPage usingChain:(SomePromise*)chain
{
	chain.spThen(^(NSString *promiseName, SomeParameterProvider *params){
		@retainNetworkIndicator
		SPArrayElementWrapper *pageJSON = ((SPPair*)params.value).right;
		NSNumber *count = ((SPPair*)params.value).left;
		return [SPPair pairWithLeft:count right:pageJSON.value];
	}, topNewsPromise, parameterProvider(pairWhithPage));
}


@end
