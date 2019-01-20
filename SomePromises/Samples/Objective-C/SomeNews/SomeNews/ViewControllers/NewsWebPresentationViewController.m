//
//  NewsWebPresentationViewController.m
//  SomeNews
//
//  Created by Sergey Makeev on 16/09/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "NewsWebPresentationViewController.h"
#import "AlertsPresenterProtocolStrategy.h"
#import "ContainerableProtocolStrategy.h"
#import "ShimmerAnimatedLabel.h"
#import <WebKit/WebKit.h>

#define kLoadExpectation 0.5

@interface NewsWebPresentationViewController () <AlertsPresenterProtocol, WKNavigationDelegate>
{
	NSString *_urlOrigin;
	NSURL *_url;
	IBOutlet UIView *_webContainer;
	WKWebView *_webView;
	__weak IBOutlet UIView *urlLabel;
	ShimmerAnimatedLabel *_urlText;
	SPEventExpector *_newPageLoadingExpector;
	UIView *_clearView;
	
	__weak IBOutlet UIButton *_extendButton;
	__weak IBOutlet UIButton *refreshCurrentURL;
	__weak IBOutlet UIButton *_refreshURL;
	__weak IBOutlet UIButton *_forwardButton;
	__weak IBOutlet UIButton *_backButton;
	__weak IBOutlet UIButton *_safariButton;
	__weak IBOutlet UIButton *_stopButton;
	
	__weak IBOutlet UILabel *progressLabel;
}


@end

@implementation NewsWebPresentationViewController
@synthesize container;
@synthesize embededControllers;

+ (void) load
{
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    	[SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(AlertsPresenterProtocol) extention:[AlertsPresenterProtocolStrategy class] whereSelf:@protocol(NSObject)];
		[SomePromiseUtils makeProtocolOriented:[self class] protocol:@protocol(Containerable) extention:[ContainerableProtocolStrategy class] whereSelf:@protocol(NSObject)];
    });
}

//@TODO:
- (UIView*) baseAlertView
{
	return nil;
}


- (void) setupWebView
{
	_webView = [[WKWebView alloc] initWithFrame:self.view.frame];
	_webView.navigationDelegate = self;
	_webView.translatesAutoresizingMaskIntoConstraints = NO;
	[_webContainer addSubview:_webView];
	[_webContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
	[_webContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
	_webView.hidden = YES;
	
	
	_clearView = [[UIView alloc] initWithFrame:CGRectZero];
	_clearView.translatesAutoresizingMaskIntoConstraints = NO;
	[_webView addSubview:_clearView];
	[_webView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_clearView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_clearView)]];
	[_webView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_clearView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_clearView)]];
	_clearView.backgroundColor = [UIColor whiteColor];
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	indicator.center = _clearView.center;
	[_clearView addSubview:indicator];
	indicator.translatesAutoresizingMaskIntoConstraints = NO;
	[indicator.centerXAnchor constraintEqualToAnchor:_clearView.centerXAnchor].active = YES;
	[indicator.centerYAnchor constraintEqualToAnchor:_clearView.centerYAnchor].active = YES;
	indicator.color = [UIColor colorNamed:@"background"];
	[indicator startAnimating];
	indicator.hidesWhenStopped = NO;
	
	@sp_uibind(self->_stopButton, enabled) = @sp_observe(_webView, loading);
	@sp_uibind(self->_backButton, enabled) = @sp_observe(_webView, canGoBack);
	@sp_uibind(self->_forwardButton, enabled) = @sp_observe(_webView, canGoForward);
	@sp_avoidblockretain(self)
	@sp_startUI(sp_action(progressLabel, ^(NSNumber *progress){
		@sp_strongify(self)
		guard(self) else {return;}
		NSInteger result = (progress.doubleValue) * 100;
		self->progressLabel.text = [NSString stringWithFormat:@"%ld%%", result];
		if(result == 100)
		{
			self->progressLabel.hidden = YES;
		}
		else
		{
			if(self->progressLabel.layer.bounds.size.width > 15)
				self->progressLabel.hidden = NO;
		}
	})) = @sp_observe(_webView, estimatedProgress);
	@sp_avoidend(self)
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_urlText = [[ShimmerAnimatedLabel alloc] initWithFrame:CGRectZero];
	_urlText.translatesAutoresizingMaskIntoConstraints = 0;
	[urlLabel addSubview:_urlText];
	[urlLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_urlText]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_urlText)]];
	[urlLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_urlText]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_urlText)]];
	_webView.hidden = YES;
	
	refreshCurrentURL.enabled = NO;
	_refreshURL.enabled = NO;
	_forwardButton.enabled = NO;
	_backButton.enabled = NO;
	_safariButton.enabled = NO;
	self->_stopButton.enabled = NO;
	
	[self setupWebView];

	@sp_avoidblockretain(self)
	@sp_uibind(progressLabel, hidden) = @sp_observe(progressLabel.layer, bounds).map(^(NSValue *bounds){
		@sp_strongify(self)
		BOOL shouldHideProgress = YES;
		if (self && bounds.CGRectValue.size.width > 15 &&
		 	![self->progressLabel.text isEqualToString:@"0%"] &&
			![self->progressLabel.text isEqualToString:@"100%"])
		{
			shouldHideProgress = NO;
		}
		return @(shouldHideProgress);
	});
	@sp_avoidend(self)
}

- (BOOL)shouldHandleSignal:(SomePromiseSignal*)signal
{
	if([signal.name isEqualToString:selectArticle])
	{
		return YES;
	}
	
	if([signal.name isEqualToString:mainScreenChangedSignal])
	{
		return YES;
	}
	
	return NO;
}

- (void) startLoading
{
	NSURLRequest* httpRequest = [[NSMutableURLRequest alloc] initWithURL:_url];
	[_webView loadRequest:httpRequest];
}

- (void) showWeb
{
	self->_webView.hidden = NO;
	self->_webView.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0);
	[UIView animateWithDuration:1.0 animations:^{
			self->_webView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {
			self->_urlText.text = self->_urlOrigin;
	}];
}

- (void) hideWeb
{
	[UIView animateWithDuration:1.0 animations:^{
		self->_webView.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0);
	} completion:^(BOOL finished) {
		self->_webView.transform = CGAffineTransformIdentity;
		self->_webView.hidden = YES;
		self->_urlText.text = @"";
		self->_clearView.hidden = NO;
		
		self->refreshCurrentURL.enabled = NO;
		self->_refreshURL.enabled = NO;
		self->_safariButton.enabled = NO;
	}];
}

 - (void)handleTheSignal:(SomePromiseSignal*)signal
 {
 	if([signal.name isEqualToString:selectArticle])
 	{
		NSInteger selectedArticleIndex = [signal.message[@"articleID"] integerValue];
		_urlOrigin = signal.message[@"url"];
		NSString *urlString = [_urlOrigin stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
		_url = [NSURL URLWithString:urlString];
		
		if(selectedArticleIndex == -1)
		{
			[self hideWeb];
		}
		else
		{
			refreshCurrentURL.enabled = YES;
			_refreshURL.enabled = YES;
	
			if(_webView.hidden == YES)
			{
				[self startLoading];
				[_newPageLoadingExpector reject];
				_newPageLoadingExpector = [SPEventExpector waitForTriggeredEventForTimeInterval:kLoadExpectation accept:^BOOL(NSDictionary*ev){
					return YES;
				} onReceived:^(NSDictionary *ev){
					[self showWeb];
				} onTimeout:(^{
					[self showWeb];
				}) waitOnThread:nil];
			}
			else
			{
				[_newPageLoadingExpector reject];
				[self startLoading];
				[UIView animateWithDuration:1.0 animations:^{
						self->_webView.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0);
				} completion:^(BOOL finished) {
					self->_clearView.hidden = NO;
					[self->_newPageLoadingExpector reject];
					self->_newPageLoadingExpector = [SPEventExpector waitForTriggeredEventForTimeInterval:kLoadExpectation accept:^BOOL(NSDictionary*ev){
						return YES;
					} onReceived:^(NSDictionary *ev){
						
						[self showWeb];
					} onTimeout:(^{
						
						[self showWeb];
				}) waitOnThread:nil];
				}];
			}
		}
		
		return;
	}
	
	if([signal.name isEqualToString:mainScreenChangedSignal])
	{
		NSString *state = signal.message[@"state"];
		if([state isEqualToString:@"Both"])
		{
			[_extendButton setImage:[UIImage imageNamed:@"extend"] forState:UIControlStateNormal];
		}
		else if([state isEqualToString:@"Right"])
		{
			[_extendButton setImage:[UIImage imageNamed:@"minimize"] forState:UIControlStateNormal];
		}
	}
 }

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
	[_newPageLoadingExpector trigger:nil];
	_clearView.hidden = YES;
}

- (IBAction)optionsPressed:(id)sender
{
	SomePromiseSignal *signalOptionsPressed = [[SomePromiseSignal alloc] initWithName:optionsPressed tag:0 message:nil anythingElse:nil];
	NSMutableSet *receivers = [NSMutableSet new];
	[self getAllReceiversForController:self set:receivers];
	[receivers removeObject:self];
	[self sendSignal:signalOptionsPressed toObject:receivers.allObjects];
}

- (IBAction)closeBtnPressed:(id)sender
{
	[self hideWeb];
	SomePromiseSignal *signalSelectArticle = [[SomePromiseSignal alloc] initWithName:unselectArticle tag:0 message:nil anythingElse:nil];
	NSMutableSet *receivers = [NSMutableSet new];
	[self getAllReceiversForController:self set:receivers];
	[receivers removeObject:self];
	[self sendSignal:signalSelectArticle toObject:receivers.allObjects];
}

- (IBAction)openInSafariPressed:(id)sender
{
	[Services.net openInSafariURL:_webView.URL];
}

- (IBAction)stopPressed:(id)sender
{
	[_webView stopLoading];
}

- (IBAction)refreshURLPressed:(id)sender
{
	[self startLoading];
}

- (IBAction)refreshCurrentURLPressed:(id)sender
{
	[_webView reload];
}

- (IBAction)backButtonPressed:(id)sender
{
	if([_webView canGoBack])
	{
		[_webView goBack];
	}
}

- (IBAction)forwardButtonPressed:(id)sender
{
	if([_webView canGoForward])
	{
		[_webView goForward];
	}
}

- (IBAction)sizeChangerPressed:(UIButton*)sender
{
	SomePromiseSignal *signalsizeChangerPressed = [[SomePromiseSignal alloc] initWithName:sizeChangingAsked tag:0 message:@{@"button" : sender, @"sender" : @"rightController"} anythingElse:nil];
	NSMutableSet *receivers = [NSMutableSet new];
	[self getAllReceiversForController:self set:receivers];
	[receivers removeObject:self];
	[self sendSignal:signalsizeChangerPressed toObject:receivers.allObjects];
}


@end
