#import <Foundation/Foundation.h>
#import "WordPressComRESTAPIVersion.h"

static NSString* const WordPressComRESTApiVersionStringInvalid = @"invalid_api_version";
static NSString* const WordPressComRESTApiVersionString_1_0 = @"rest/v1";
static NSString* const WordPressComRESTApiVersionString_1_1 = @"rest/v1.1";
static NSString* const WordPressComRESTApiVersionString_1_2 = @"rest/v1.2";
static NSString* const WordPressComRESTApiVersionString_1_3 = @"rest/v1.3";
static NSString* const WordPressComRESTApiVersionString_2_0 = @"wpcom/v2";

@implementation WordPressComRESTAPIVersionedPathBuilder

+ (NSString *)pathForEndpoint:(NSString *)endpoint 
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
{
    NSString *apiVersionString = [self apiVersionStringWithEnumValue:apiVersion];

    return [NSString stringWithFormat:@"%@/%@", apiVersionString, endpoint];
}

+ (NSString *)apiVersionStringWithEnumValue:(WordPressComRESTAPIVersion)apiVersion
{
    NSString *result = nil;

    switch (apiVersion) {
        case WordPressComRESTAPIVersion_1_0:
            result = WordPressComRESTApiVersionString_1_0;
            break;

        case WordPressComRESTAPIVersion_1_1:
            result = WordPressComRESTApiVersionString_1_1;
            break;

        case WordPressComRESTAPIVersion_1_2:
            result = WordPressComRESTApiVersionString_1_2;
            break;

        case WordPressComRESTAPIVersion_1_3:
            result = WordPressComRESTApiVersionString_1_3;
            break;

        case WordPressComRESTAPIVersion_2_0:
            result = WordPressComRESTApiVersionString_2_0;
            break;

        default:
            NSAssert(NO, @"This should never by executed");
            result = WordPressComRESTApiVersionStringInvalid;
            break;
    }

    return result;
}

@end
