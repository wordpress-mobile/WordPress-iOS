#import "WPUserAgent.h"
#import "WordPress-Swift.h"

@import WebKit;

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@implementation WPUserAgent

+ (NSString *)defaultUserAgent
{
    return [TemporaryWPUserAgent defaultUserAgentWithUserDefaults:[UserPersistentStoreFactory userDefaultsInstance]];
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
    [[UserPersistentStoreFactory userDefaultsInstance] removeObjectForKey:@"DefaultUserAgent"];
    [[UserPersistentStoreFactory userDefaultsInstance] removeObjectForKey:@"AppUserAgent"];

    NSString *userAgent = [self wordPressUserAgent];

    NSParameterAssert([userAgent isKindOfClass:[NSString class]]);
    
    NSDictionary *dictionary = @{WPUserAgentKeyUserAgent: userAgent};
    // We have to call registerDefaults else the change isn't picked up by WKWebViews.
    [[UserPersistentStoreFactory userDefaultsInstance] registerDefaults:dictionary];
    
    DDLogVerbose(@"User-Agent set to: %@", userAgent);
}

@end
