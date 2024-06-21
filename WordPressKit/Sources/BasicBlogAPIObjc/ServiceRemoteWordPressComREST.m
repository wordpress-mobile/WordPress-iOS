#import "ServiceRemoteWordPressComREST.h"
#import "WPKit-Swift.h"

@implementation ServiceRemoteWordPressComREST

- (instancetype)initWithWordPressComRestApi:(WordPressComRestApi *)wordPressComRestApi {

    NSParameterAssert([wordPressComRestApi isKindOfClass:[WordPressComRestApi class]]);

    self = [super init];
    if (self) {
        _wordPressComRestApi = wordPressComRestApi;
        _wordPressComRESTAPI = wordPressComRestApi;
    }
    return self;
}

#pragma mark - Request URL construction

- (NSString *)pathForEndpoint:(NSString *)resourceUrl
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
{
    NSParameterAssert([resourceUrl isKindOfClass:[NSString class]]);

    return [WordPressComRESTAPIVersionedPathBuilder pathForEndpoint:resourceUrl
                                                        withVersion:apiVersion];
}

@end
