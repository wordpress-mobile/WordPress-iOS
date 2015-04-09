#import "WPLookbackPresenter.h"

#import <Lookback/Lookback.h>

NSString* const WPLookbackPresenterShakeToPullUpFeedbackKey = @"InternalBetaShakeToPullUpFeedback";

@interface WPLookbackPresenter ()
@property (nonatomic, strong, readwrite) UILongPressGestureRecognizer *gestureRecognizer;
@property (nonatomic, strong, readwrite) UIWindow *window;
@end

@implementation WPLookbackPresenter

#pragma mark - Dealloc

- (void)dealloc
{
    [self.window removeGestureRecognizer:self.gestureRecognizer];
}

#pragma mark - Initialization

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (instancetype)initWithToken:(NSString*)token
                       userId:(NSString*)userId
                       window:(UIWindow*)window
{
    NSParameterAssert([token isKindOfClass:[NSString class]]);
    NSParameterAssert([token length] > 0);
    NSParameterAssert([window isKindOfClass:[UIWindow class]]);
    
    self = [super init];
    
    if (self) {
        _window = window;
        
        [self setupLookbackWithToken:token
                              userId:userId
                              window:window];
    }
    
    return self;
}

#pragma mark - One time setup

- (void)setupLookbackWithToken:(NSString*)token
                        userId:(NSString*)userId
                        window:(UIWindow*)window
{
    NSParameterAssert([token isKindOfClass:[NSString class]]);
    NSParameterAssert([token length] > 0);
    NSParameterAssert([window isKindOfClass:[UIWindow class]]);
    
#ifndef LOOKBACK_ENABLED
    NSAssert(NO,
             @"This method should not be called when lookback is disabled");
#else
    [Lookback setupWithAppToken:token];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPLookbackPresenterShakeToPullUpFeedbackKey: @YES}];
    [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:LookbackCameraEnabledSettingsKey];
    [Lookback lookback].shakeToRecord = [[NSUserDefaults standardUserDefaults] boolForKey:WPLookbackPresenterShakeToPullUpFeedbackKey];
    
    // Setup Lookback to fire when the user holds down with three fingers for around 3 seconds
    dispatch_async(dispatch_get_main_queue(), ^{
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lookbackGestureRecognized:)];
        recognizer.minimumPressDuration = 3;
            recognizer.cancelsTouchesInView = NO;
#if TARGET_IPHONE_SIMULATOR
        recognizer.numberOfTouchesRequired = 2;
#else
        recognizer.numberOfTouchesRequired = 3;
#endif
        self.gestureRecognizer = recognizer;
        
        [window addGestureRecognizer:recognizer];
    });
    
    [Lookback lookback].userIdentifier = userId;
#endif
}

#pragma mark - Gestures recognition

- (void)lookbackGestureRecognized:(UILongPressGestureRecognizer *)sender
{
#ifndef LOOKBACK_ENABLED
    NSAssert(NO,
             @"This method should not be called when lookback is disabled");
#else
    if (sender.state == UIGestureRecognizerStateBegan) {
        [LookbackRecordingViewController presentOntoScreenAnimated:YES];
    }
#endif
}

@end


