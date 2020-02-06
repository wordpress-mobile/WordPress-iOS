#import "WPUserAgent.h"
#import "WordPress-Swift.h"

@import WebKit;

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@implementation WPUserAgent

+ (NSString *)defaultUserAgent
{
    static NSString * _defaultUserAgent;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        NSDictionary * registrationDomain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];
        NSString *storeCurrentUA = [registrationDomain objectForKey:WPUserAgentKeyUserAgent];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: @(0)}];
        
        if ([NSThread isMainThread]){
            _defaultUserAgent = [WKWebView userAgent];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                _defaultUserAgent = [WKWebView userAgent];
            });
        }
        if (storeCurrentUA) {
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPUserAgentKeyUserAgent: storeCurrentUA}];
        }
    });
    NSAssert(_defaultUserAgent != nil, @"User agent shouldn't be nil");
    NSAssert([_defaultUserAgent length] > 0, @"User agent shouldn't be empty");

    return _defaultUserAgent;
}

+ (NSString *)wordPressUserAgent
{
    static NSString * _wordPressUserAgent;
    if (_wordPressUserAgent == nil) {
        NSString *defaultUA = [self defaultUserAgent];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        _wordPressUserAgent = [NSString stringWithFormat:@"%@ wp-iphone/%@", defaultUA, appVersion];
    }
    
    return _wordPressUserAgent;
}

+ (void)useWordPressUserAgentInWebViews
{
    // Cleanup unused NSUserDefaults keys from older WPUserAgent implementation
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DefaultUserAgent"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppUserAgent"];

    NSString *userAgent = [self wordPressUserAgent];

    NSParameterAssert([userAgent isKindOfClass:[NSString class]]);
    
    NSDictionary *dictionary = @{WPUserAgentKeyUserAgent: userAgent};
    // We have to call registerDefaults else the change isn't picked up by WKWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    DDLogVerbose(@"User-Agent set to: %@", userAgent);
}

@end
