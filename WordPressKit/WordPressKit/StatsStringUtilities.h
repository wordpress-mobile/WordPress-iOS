#import <Foundation/Foundation.h>

@interface StatsStringUtilities : NSObject

- (NSString *)sanitizePostTitle:(NSString *) postTitle;

// Sanitizes a post title and, if the title is empty, returns a
// displayable title '(no title)' following what Calypso does
- (NSString *)displayablePostTitle:(NSString *)postTitle;

@end
