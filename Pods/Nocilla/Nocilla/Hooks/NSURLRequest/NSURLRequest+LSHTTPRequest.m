#import "NSURLRequest+LSHTTPRequest.h"

@implementation NSURLRequest (LSHTTPRequest)

- (NSURL*)url {
    return self.URL;
}

- (NSString *)method {
    return self.HTTPMethod;
}

- (NSDictionary *)headers {
    return self.allHTTPHeaderFields;
}
- (NSData *)body {
    return self.HTTPBody;
}

@end
