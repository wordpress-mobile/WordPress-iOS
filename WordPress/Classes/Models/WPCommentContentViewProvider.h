#import <Foundation/Foundation.h>
#import "PostContentProvider.h"

@protocol WPCommentContentViewProvider <PostContentProvider>

- (BOOL)isLiked;
- (BOOL)authorIsPostAuthor;
- (NSNumber *)numberOfLikes;
- (BOOL)isPrivateContent;

@end
