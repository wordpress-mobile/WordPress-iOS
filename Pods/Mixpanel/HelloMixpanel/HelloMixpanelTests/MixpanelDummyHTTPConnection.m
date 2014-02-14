#import "HTTPDataResponse.h"
#import "MixpanelDummyHTTPConnection.h"

@implementation MixpanelDummyHTTPConnection

static int requestCount;

+ (void)initialize
{
    requestCount = 0;
}

+ (int)getRequestCount
{
    return requestCount;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    requestCount += 1;
    return [[HTTPDataResponse alloc] initWithData:[@"1" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    return [super supportsMethod:method atPath:path] || [method isEqualToString:@"POST"];
}

@end
