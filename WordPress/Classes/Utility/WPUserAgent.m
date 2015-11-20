#import "WPUserAgent.h"

static NSString* const WPUserAgentKeyUserAgent = @"UserAgent";
static NSString* const WPUserAgentKeyDefaultUserAgent = @"DefaultUserAgent";
static NSString* const WPUserAgentKeyWordPressUserAgent = @"AppUserAgent";

@implementation WPUserAgent

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setupUserAgent];
    }
    
    return self;
}

#pragma mark - One time setup

- (void)setupUserAgent
{
    // Keep a copy of the original userAgent for use with certain webviews in the app.
    NSString *defaultUA = [self defaultUserAgent];
    NSString *wordPressUserAgent = [self wordPressUserAgent];

    NSDictionary *dictionary = @{
                                 WPUserAgentKeyUserAgent : wordPressUserAgent,
                                 WPUserAgentKeyDefaultUserAgent : defaultUA,
                                 WPUserAgentKeyWordPressUserAgent : wordPressUserAgent
                                 };
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

#pragma mark - Default and WordPress User-Agents

- (NSString *)defaultUserAgent
{
    // Temporarily unset "UserAgent" from registered user defaults so that we
    // always get the default value, independently from what's currently set as
    // User-Agent
    NSDictionary *originalRegisteredDefaults = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];

    NSMutableDictionary *tempRegisteredDefaults = [NSMutableDictionary dictionaryWithDictionary:originalRegisteredDefaults];
    [tempRegisteredDefaults removeObjectForKey:WPUserAgentKeyUserAgent];
    [[NSUserDefaults standardUserDefaults] registerDefaults:tempRegisteredDefaults];
    
    NSString *userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSAssert(userAgent != nil, @"User agent shouldn't be nil");
    NSAssert(! [userAgent isEmpty], @"User agent shouldn't be empty");
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:originalRegisteredDefaults];
    
    return userAgent;
}

- (NSString *)wordPressUserAgent
{
    NSString *defaultUA = [self defaultUserAgent];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *userAgent = [NSString stringWithFormat:@"%@ wp-iphone/%@", defaultUA, appVersion];
    
    return userAgent;
}

#pragma mark - Changing the user agent

- (void)useDefaultUserAgent
{
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:WPUserAgentKeyDefaultUserAgent];
    
    [self setUserAgent:ua];
}

- (void)useWordPressUserAgent
{
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:WPUserAgentKeyWordPressUserAgent];
    
    [self setUserAgent:ua];
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
