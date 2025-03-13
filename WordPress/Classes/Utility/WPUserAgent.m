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
        NSDictionary * registrationDomain = [[UserPersistentStoreFactory userDefaultsInstance] volatileDomainForName:NSRegistrationDomain];
        NSString *storeCurrentUA = [registrationDomain objectForKey:WPUserAgentKeyUserAgent];
        [[UserPersistentStoreFactory userDefaultsInstance] registerDefaults:@{WPUserAgentKeyUserAgent: @(0)}];

        _defaultUserAgent = [self webViewUserAgent];

        if (storeCurrentUA) {
            [[UserPersistentStoreFactory userDefaultsInstance] registerDefaults:@{WPUserAgentKeyUserAgent: storeCurrentUA}];
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

@end
