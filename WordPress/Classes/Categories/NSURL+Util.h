#import <Foundation/Foundation.h>

@interface NSURL (Util)

- (BOOL)isWordPressDotComUrl;
- (NSURL *)ensureSecureURL;
- (NSURL *)patchGravatarUrlWithSize:(CGFloat)size;

@end
