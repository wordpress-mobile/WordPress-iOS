#import <Foundation/Foundation.h>

@interface NSURL (Util)

- (BOOL)isWordPressDotComUrl;
- (BOOL)isUnknownGravatarUrl;

- (NSURL *)ensureSecureURL;
- (NSURL *)patchGravatarUrlWithSize:(CGFloat)size;

@end
