#import "ServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "WPApiVersionConstants.h"

@interface ServiceRemoteREST ()
@end

@implementation ServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
    
    NSParameterAssert([api isKindOfClass:[WordPressComApi class]]);
    
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

#pragma mark - Request URL construction

- (NSString *)requestUrlForApiVersion:(NSString *)apiVersion
                          resourceUrl:(NSString *)resourceUrl
{
    NSParameterAssert([apiVersion isKindOfClass:[NSString class]]);
    NSParameterAssert([resourceUrl isKindOfClass:[NSString class]]);
    
    return [NSString stringWithFormat:@"%@/%@", apiVersion, resourceUrl];
}

- (NSString *)requestUrlForDefaultApiVersionAndResourceUrl:(NSString *)resourceUrl
{
    NSParameterAssert([resourceUrl isKindOfClass:[NSString class]]);
    
    return [self requestUrlForApiVersion:WPApiVersionDefault resourceUrl:resourceUrl];
}

@end
