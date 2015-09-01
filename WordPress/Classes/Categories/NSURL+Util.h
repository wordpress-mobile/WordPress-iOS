#import <Foundation/Foundation.h>

@interface NSURL (Util)

- (BOOL)isWordPressDotComUrl;
- (BOOL)isUnknownGravatarUrl;

- (NSURL *)ensureSecureURL;
- (NSURL *)removeGravatarFallback;
- (NSURL *)patchGravatarUrlWithSize:(CGFloat)size;

@end
