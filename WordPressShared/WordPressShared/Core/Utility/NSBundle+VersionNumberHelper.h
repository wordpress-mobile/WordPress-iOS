#import <Foundation/Foundation.h>

@interface NSBundle (VersionNumberHelper)

- (NSString *)detailedVersionNumber;
- (NSString *)shortVersionString;
- (NSString *)bundleVersion;

@end
