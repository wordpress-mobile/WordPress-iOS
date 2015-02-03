#import <Foundation/Foundation.h>
#import "WPContentViewProvider.h"

@protocol WPCommentContentViewProvider <WPContentViewProvider>

- (BOOL)isLiked;
- (BOOL)authorIsPostAuthor;
- (NSNumber *)numberOfLikes;
- (BOOL)isPrivateContent;

@end
