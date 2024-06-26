#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WordPressComRESTAPIVersion) {
    WordPressComRESTAPIVersion_1_0 = 1000,
    WordPressComRESTAPIVersion_1_1 = 1001,
    WordPressComRESTAPIVersion_1_2 = 1002,
    WordPressComRESTAPIVersion_1_3 = 1003,
    WordPressComRESTAPIVersion_2_0 = 2000
};

@interface WordPressComRESTAPIVersionedPathBuilder: NSObject

+ (NSString *)pathForEndpoint:(NSString *)endpoint
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
NS_SWIFT_NAME(path(forEndpoint:withVersion:));

@end
