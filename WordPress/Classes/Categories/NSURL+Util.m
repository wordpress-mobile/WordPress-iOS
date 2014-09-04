#import "NSURL+Util.h"
#import "NSString+Util.h"

@implementation NSURL (Util)

- (BOOL)isWordPressDotComUrl
{
    NSString *url = [self absoluteString];
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[url trim] options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [[url trim] length])];

    return [result count] != 0;
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
