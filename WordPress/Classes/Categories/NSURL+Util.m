#import "NSURL+Util.h"
#import "NSString+Util.h"
#import "NSString+Helpers.h"

@implementation NSURL (Util)

- (BOOL)isWordPressDotComUrl
{
    return [self.absoluteString isWordPressComPath];
}

- (NSURL *)ensureSecureURL
{
    NSString *url = [self absoluteString];
    return [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
}

- (NSURL *)patchGravatarUrlWithSize:(CGFloat)size
{
    NSString *patchedURL        = [self absoluteString];
    NSString *parameterScale    = [NSString stringWithFormat:@"s=%.0f", size];

    return [NSURL URLWithString:[patchedURL stringByReplacingOccurrencesOfString:@"s=256" withString:parameterScale]];
}

@end
