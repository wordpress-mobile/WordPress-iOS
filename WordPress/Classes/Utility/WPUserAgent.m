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
    NSString *defaultUA = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString *wordPressUserAgent = [self wordPressUserAgent];

    NSDictionary *dictionary = @{
                                 WPUserAgentKeyUserAgent : wordPressUserAgent,
                                 WPUserAgentKeyDefaultUserAgent : defaultUA,
                                 WPUserAgentKeyWordPressUserAgent : wordPressUserAgent
                                 };
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

#pragma mark - WordPress User-Agent

- (NSString *)wordPressUserAgent
{
    UIDevice *device = [UIDevice currentDevice];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *userAgent = [NSString stringWithFormat:@"wp-iphone/%@ (%@ %@, %@) Mobile",
                           appVersion,
                           device.systemName,
                           device.systemVersion,
                           device.model];
    
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
