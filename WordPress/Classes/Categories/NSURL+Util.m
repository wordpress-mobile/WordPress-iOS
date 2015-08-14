#import "NSURL+Util.h"
#import "NSString+Util.h"
#import "NSString+Helpers.h"
#import "Constants.h"


@implementation NSURL (Util)

- (BOOL)isWordPressDotComUrl
{
    NSString *url = [self absoluteString];
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[url trim] options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [[url trim] length])];

    return [result count] != 0;
}

- (BOOL)isUnknownGravatarUrl
{
    // Build the "Unknown Gravatar" URL
    NSString *unknownEmail          = @"unknown@gravatar.com";
    NSString *unknownPath           = [NSString stringWithFormat:@"%@/%@", WPGravatarBaseURL, unknownEmail.md5];
    NSURL *unknownURL               = [NSURL URLWithString:unknownPath];

    // Note:
    // Due to CDN and custom sizing, we might receive a Gravatar URL that looks like this:
    //  -    http://0.gravatar.com/avatar/12345?s=256&r=G
    //
    // While our 'Calculated' URL might look like this:
    //  -   http://www.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536
    //
    // In this helper we'll do some cleanup, so that we:
    //  -   (A) remove the schema
    //  -   (B) remove the query
    //  -   (C) disregard the subdomain information
    //
    
    NSString *schemalessSelfURL     = [NSString stringWithFormat:@"%@%@", self.host, self.path];
    NSString *schemalessUknownURL   = [NSString stringWithFormat:@"%@%@", unknownURL.host, unknownURL.path];
    
    return [schemalessSelfURL rangeOfString:schemalessUknownURL].location != NSNotFound;
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
