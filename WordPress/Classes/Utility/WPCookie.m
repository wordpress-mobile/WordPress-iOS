#import "WPCookie.h"

static NSString * const WPCookieName = @"wordpress_logged_in";

@implementation WPCookie

+ (BOOL)hasCookieForURL:(NSURL *)url
{
    return [self hasCookieForURL:url andUsername:nil];
}

+ (BOOL)hasCookieForURL:(NSURL *)url andUsername:(NSString *)username
{
    NSAssert(url != nil, @"url shouldn't be nil");
    if (![url isKindOfClass:[NSURL class]]) {
        return NO;
    }
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:WPCookieName]) {
            if (!username) {
                return YES;
            }
            NSString *value = cookie.value;
            NSArray *components = [value componentsSeparatedByString:@"%"];
            if ([components count] > 0) {
                NSString *cookieUsername = components[0];
                if ([cookieUsername isEqualToString:username]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

@end
