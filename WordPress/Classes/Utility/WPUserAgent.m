#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";

@interface WPUserAgent ()

@property (nonatomic, strong) NSString *defaultUserAgent;
@property (nonatomic, strong) NSString *wordPressUserAgent;

@end

@implementation WPUserAgent

#pragma mark - Default and WordPress User-Agents

- (NSString *)defaultUserAgent
{
    if (! _defaultUserAgent) {
        // Temporarily unset "UserAgent" from registered user defaults so that we
        // always get the default value, independently from what's currently set as
        // User-Agent
        NSDictionary *originalRegisteredDefaults = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];

        NSMutableDictionary *tempRegisteredDefaults = [NSMutableDictionary dictionaryWithDictionary:originalRegisteredDefaults];
        [tempRegisteredDefaults removeObjectForKey:WPUserAgentKeyUserAgent];
        [[NSUserDefaults standardUserDefaults] registerDefaults:tempRegisteredDefaults];
        
        _defaultUserAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        NSAssert(_defaultUserAgent != nil, @"User agent shouldn't be nil");
        NSAssert(! [_defaultUserAgent isEmpty], @"User agent shouldn't be empty");
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:originalRegisteredDefaults];
    }
    
    return _defaultUserAgent;
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

#pragma mark - Changing the user agent

- (void)useWordPressUserAgent
{
    [self setUserAgent:[self wordPressUserAgent]];
}

- (void)setUserAgent:(NSString*)userAgent
{
    NSParameterAssert([userAgent isKindOfClass:[NSString class]]);
    
    NSDictionary *dictionary = @{WPUserAgentKeyUserAgent: userAgent};
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    DDLogVerbose(@"User-Agent set to: %@", userAgent);
}

#pragma mark - Getting the user agent

- (NSString *)currentUserAgent
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WPUserAgentKeyUserAgent];
}


@end
