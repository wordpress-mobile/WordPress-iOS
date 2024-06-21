#import <Foundation/Foundation.h>
#if SWIFT_PACKAGE
#import "WordPressComRESTAPIVersion.h"
#else
#import <WordPressKit/WordPressComRESTAPIVersion.h>
#endif

@interface WordPressComRESTAPIVersionedPathBuilder: NSObject

+ (NSString *)pathForEndpoint:(NSString *)endpoint
                  withVersion:(WordPressComRESTAPIVersion)apiVersion
NS_SWIFT_NAME(path(forEndpoint:withVersion:));

@end
