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

- (NSDictionary *)queryDictionary
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[self query] componentsSeparatedByString:@"&"]) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if([parts count] < 2) continue;
        [params setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    return params;
}

@end
