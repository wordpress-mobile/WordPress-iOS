#import "ServiceRemoteWordPressComREST.h"
#import <WordPressKit/WordPressKit-Swift.h>

static NSString* const ServiceRemoteWordPressComRESTApiVersionStringInvalid = @"invalid_api_version";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_1 = @"v1.1";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_2 = @"v1.2";
static NSString* const ServiceRemoteWordPressComRESTApiVersionString_1_3 = @"v1.3";

@interface ServiceRemoteWordPressComREST ()
@end

@implementation ServiceRemoteWordPressComREST

- (id)initWithWordPressComRestApi:(WordPressComRestApi *)wordPressComRestApi {

    NSParameterAssert([wordPressComRestApi isKindOfClass:[WordPressComRestApi class]]);

    self = [super init];
    if (self) {
        _wordPressComRestApi = wordPressComRestApi;
    }
    return self;
}


#pragma mark - API Version

- (NSString *)apiVersionStringWithEnumValue:(ServiceRemoteWordPressComRESTApiVersion)apiVersion
{
    NSString *result = nil;
    
    switch (apiVersion) {
        case ServiceRemoteWordPressComRESTApiVersion_1_1:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_1;
            break;
            
        case ServiceRemoteWordPressComRESTApiVersion_1_2:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_2;
            break;

        case ServiceRemoteWordPressComRESTApiVersion_1_3:
            result = ServiceRemoteWordPressComRESTApiVersionString_1_3;
            break;

        default:
            NSAssert(NO, @"This should never by executed");
            result = ServiceRemoteWordPressComRESTApiVersionStringInvalid;
            break;
    }
    
    return result;
}

#pragma mark - Request URL construction

- (NSString *)pathForEndpoint:(NSString *)resourceUrl
                  withVersion:(ServiceRemoteWordPressComRESTApiVersion)apiVersion
{
    NSParameterAssert([resourceUrl isKindOfClass:[NSString class]]);
    
    NSString *apiVersionString = [self apiVersionStringWithEnumValue:apiVersion];
    
    return [NSString stringWithFormat:@"%@/%@", apiVersionString, resourceUrl];
}

+ (WordPressComRestApi *)anonymousWordPressComRestApiWithUserAgent:(NSString *)userAgent {

    return [[WordPressComRestApi alloc] initWithOAuthToken:nil
                                                 userAgent:userAgent
            ];
}

@end
