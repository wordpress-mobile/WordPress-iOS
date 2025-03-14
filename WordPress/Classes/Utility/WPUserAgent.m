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
