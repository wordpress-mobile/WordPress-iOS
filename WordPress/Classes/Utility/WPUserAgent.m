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
    return [TemporaryWPUserAgent wordPressUserAgentWithUserDefaults:[UserPersistentStoreFactory userDefaultsInstance] bundle:[NSBundle mainBundle]];
}

+ (void)useWordPressUserAgentInWebViews
{
    [TemporaryWPUserAgent useWordPressUserAgentInWebViewsWithUserDefaults:[UserPersistentStoreFactory userDefaultsInstance]];
}

@end
