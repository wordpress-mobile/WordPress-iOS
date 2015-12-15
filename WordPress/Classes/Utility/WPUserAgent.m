#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@interface WPUserAgent ()

// Default UA to append "wp-iphone/<version>" to
- (NSString *)defaultUserAgent;

@property (nonatomic, strong, readwrite) NSString *wordPressUserAgent;

@end

@implementation WPUserAgent

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Cleanup unused NSUserDefaults keys from older WPUserAgent implementation
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DefaultUserAgent"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppUserAgent"];
    }
    return self;
}

- (NSString *)defaultUserAgent
{
    // Temporarily unset "UserAgent" from registered user defaults so that we
    // always get the default value, independently from what's currently set as
    // User-Agent
    NSDictionary *originalRegisteredDefaults = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];

    NSMutableDictionary *tempRegisteredDefaults = [NSMutableDictionary dictionaryWithDictionary:originalRegisteredDefaults];
    [tempRegisteredDefaults removeObjectForKey:WPUserAgentKeyUserAgent];
    [[NSUserDefaults standardUserDefaults] registerDefaults:tempRegisteredDefaults];
    
    NSString *defaultUserAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSAssert(defaultUserAgent != nil, @"User agent shouldn't be nil");
    NSAssert([defaultUserAgent length] > 0, @"User agent shouldn't be empty");
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:originalRegisteredDefaults];
    
    return defaultUserAgent;
}

- (NSString *)wordPressUserAgent
{
    if (! _wordPressUserAgent) {
        NSString *defaultUA = [self defaultUserAgent];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        _wordPressUserAgent = [NSString stringWithFormat:@"%@ wp-iphone/%@", defaultUA, appVersion];
    }
    
    return _wordPressUserAgent;
}

- (void)useWordPressUserAgentInUIWebViews
{
    NSString *userAgent = [self wordPressUserAgent];

    NSParameterAssert([userAgent isKindOfClass:[NSString class]]);
    
    NSDictionary *dictionary = @{WPUserAgentKeyUserAgent: userAgent};
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    DDLogVerbose(@"User-Agent set to: %@", userAgent);
}

@end
