//
//  SPDataStreamViewController.m
//  SomePromises
//
//  Created by Sergey Makeev on 05/08/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

#import "SPDataStreamViewController.h"
#import "SomePromise.h"

@interface KVOTest : NSObject
@property (nonatomic, copy) NSString *user;
@end

@implementation KVOTest
@end

@interface SPDataStreamViewController () <SPDataStreamDelegate>
{
	KVOTest *_kvoTest;
	SPDataStream *_dataKVOStream;
	SomePromiseThread *_testThread;
	NSTimer *_timer;
	
	__weak IBOutlet UILabel *_label;
	__weak IBOutlet UITextField *_text;
	__weak IBOutlet UIButton *_button;

	__weak IBOutlet UILabel *_labelTextView;
	
	__weak IBOutlet UITextView *_textView;


	__weak IBOutlet UISwitch *_switch;
	
	__weak IBOutlet UILabel *_labelSwitch;
	
	__weak IBOutlet UILabel *_labelSwitch1;
	
	__weak IBOutlet UIButton *_commandButton;
	
	IBOutlet UIProgressView *_progressView;
	SPCommand *_command;
	SomePromiseThread *_commandTestThread;
}

@property (nonatomic, copy) NSString *debugInfo;

@end

@implementation SPDataStreamViewController

- (void) setDebugInfo:(NSString *)debugInfo
{
	_debugInfo = debugInfo;
	NSLog(@"!!!!! Debug info: %@", _debugInfo);
}

- (IBAction)buttonPressed:(id)sender
{
	NSLog(@"Standard button pressed is working too");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[_button spExtend:@"extendValue" defaultValue:@"button" setter:nil getter:nil];
	
    NSArray *testArray = @[@"A", @"B", @"AB", @"ABC", @"ABDFG", @"QWERTY"];
	//Task example.
    //to result get first 3 letters of each word.
    //ommit if less than 3.
    //elso ommit if result == "ABC"
	
    SPDataStream *dataStream = [SPDataStream new];
    dataStream.delegate = self;
    [dataStream collectToArray:YES];
    [dataStream ignoreIncomingNil:YES];
    dataStream.filter(^(NSString *element){
		return (BOOL)(element.length >= 3);
	}).map(^(NSString *element){
		NSString *result = [element substringWithRange:NSMakeRange(0, 3)];
		return	[result isEqualToString:@"ABC"] ? nil : result;
	});

	[dataStream fromArray:testArray];
	[dataStream doComplete];
	NSArray *result = dataStream.collectedArray;
	NSLog(@"result : %@", result);
	
	
	/// check for KVO observing
	_kvoTest = [[KVOTest alloc] init];
	_dataKVOStream = @sp_observe(_kvoTest, user);//[SPDataStream newWithSource:_kvoTest keyPath:@"user"];
	_dataKVOStream.delegate = self;
	_testThread = [SomePromiseThread threadWithName:@"kvo test"];
	
	
	@sp_observe(_kvoTest, user); //To test that observer deletion works fine.
	
	@sp_avoidblockretain(self)
	
		_timer = [_testThread scheduledTimerWithTimeInterval:2.5 repeats:YES block:^(NSTimer *timer) {
				@sp_strongify(self)
				guard(self) else {
					return;
				}
			
				static int count = 0;
				switch (count)
				{
					case 0:
						self->_kvoTest.user = @"1st user A";
						break;
					case 1:
						self->_kvoTest.user = @"2nd user BE";
						break;
					case 2:
						self->_kvoTest.user = @"3d user Cee!";
						break;
					default:
						self->_kvoTest = nil;
						[self->_timer invalidate];
						count = 0;
				}
				count++;
			}];
	@sp_avoidend(self)

	@sp_bind(self, debugInfo) = @sp_observe(_kvoTest, user).map(^(NSString* value){
									return [NSString stringWithFormat:@"%lu", (unsigned long)value.length];
								});
	
	@sp_uibind(_label, text) = @sp_observeTextField(_text).map(^(NSString* value){
									return [NSString stringWithFormat:@"text:%@, length:%lu", value, (unsigned long)value.length];
								});
	_text.text = @"First text";
	
	@sp_uibind(_labelTextView, text) = @sp_observeTextView(_textView);
	_textView.text = @"First text for test";
	
	@sp_uibind(_labelSwitch, text) = @sp_observeSwitch(_switch).map(^(NSNumber *value){
																	return [value boolValue] ? @"YES" : @"NO";
																});
	
	@sp_uibind(_labelSwitch1, text) = @sp_observeControl(_switch, UIControlEventValueChanged).map(^(UISwitch *value){
																	return value.isOn ? @"YES" : @"NO";
														});
	@sp_avoidblockretain(self)
		@sp_startUI(sp_action(_button, ^(UIButton *button){
			@sp_strongify(self)
			guard(self) else return;
			self->_text.text = @"First text 11";
			self->_textView.text =  @"First text 11";
			self->_switch.on = !self->_switch.isOn;
			static int number = 0;
			number++;
			NSString *newTitle = [NSString stringWithFormat:@"Tapped:%d times.", number];
			[button setTitle:newTitle forState:UIControlStateNormal];
			[button spTrigger:@"PressedEvent" message:nil];
			
			if(![button spHas:@"extendValue"])
			{
				[button spExtend:@"extendValue" defaultValue:newTitle setter:nil getter:nil];
			}
			else
			{
				[button spSet:@"extendValue" value:newTitle];
			}
			
		})) =  @sp_observeControl(_button, UIControlEventTouchUpInside);
	@sp_avoidend(self)
	
	@sp_start(sp_action(_text, ^(NSNotification *notification){
		NSLog(@"!!! Notification:%@", notification);
	})) = @sp_observeNSNotification(nil, _text, UITextFieldTextDidEndEditingNotification);
	
	@sp_start(sp_action(_button, ^(NSDictionary *msg){
		NSLog(@"!!! Button pressed event");
	})) = @sp_observeEvent(_button, @"PressedEvent");
	
	@sp_start(sp_action(_button, ^(NSString *extendValue){
		NSLog(@"!!! button extendValue:%@", extendValue);
	})) = @sp_observeExtend(_button, @"extendValue");
	
	///command test
	
	_commandTestThread = [SomePromiseThread threadWithName:@"spcommand symulationthread"];
	
	@sp_avoidblockretain(self)
		_command = [[SPCommand alloc] initWithEnableBlock:^{
					@sp_strongify(self)
					return self->_commandButton.enabled;
				}
				streamBlock:^(SomePromiseThread *thread){
					SPDataStream *stream = [SPDataStream newOnQueue:dispatch_get_main_queue() times:0];
					//here we simulate some long async operation returning some data by portions
					//e.g downloading of a file.
					[thread scheduledTimerWithTimeInterval:1.5 repeats:YES block:^(NSTimer *timer) {
							NSNumber *lastresult = stream.lastResult;
							guard(lastresult) else { [stream doNext:@(.05f)]; return; }
							[stream doNext:@(lastresult.floatValue + .05)];
							guard(lastresult.floatValue < 0.95) else {
								[timer invalidate];
								[stream doComplete];
							}
					}];
					return stream;
				}
				doNext:^(NSNumber *value)
				{
					@sp_strongify(self)
					self->_progressView.progress = [value floatValue];
				}
				doError:^(NSError *error)
				{
					@sp_strongify(self)
					self->_progressView.progress = 0;
				}
				doComplete:^{
					@sp_strongify(self)
					self->_commandButton.enabled = YES;
				}];

		@sp_startUI(sp_action(_commandButton, ^(UIButton *button){
			@sp_strongify(self)
			guard(self) else return;
			self->_progressView.progress = 0.0f;
			[self->_command execute:self->_testThread];
			self->_commandButton.enabled = NO;
		})) =  @sp_observeControl(_commandButton, UIControlEventTouchUpInside);
	@sp_avoidend(self)
}

- (void) dealloc
{
	[_timer invalidate];
}

- (void) stream:(SPDataStream*)stream hasIncomingData:(id)value
{
	NSLog(@"incoming data: %@", value);
}

- (void) stream:(SPDataStream*)stream willUpdatedWith:(id)value
{
	NSLog(@"want to Update to: %@", value);
}

- (void) stream:(SPDataStream*)stream hasUpdatedTo:(id)value
{
		NSLog(@"Updated to: %@", value);
}

- (void) streamCompleted:(SPDataStream*)stream
{
	NSLog(@"Stream Completed");
}

@end
