#import "ServiceRemoteWordPressComREST.h"
#import "WordPressComRESTAPIVersionedPathBuilder.h"

@implementation ServiceRemoteWordPressComREST

- (instancetype)initWithWordPressComRestApi:(id<WordPressComRESTAPIInterfacing>)wordPressComRestApi {
    self = [super init];
    if (self) {
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
