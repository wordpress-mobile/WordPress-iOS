#import <Foundation/Foundation.h>

@interface NSURL (Util)

- (BOOL)isWordPressDotComUrl;
- (NSURL *)ensureSecureURL;
- (NSDictionary*)queryDictionary;

@end
