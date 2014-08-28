#import <UIKit/UIKit.h>
#import "AbstractPostsViewController.h"
#import "ReaderPostContentView.h"

@interface ReaderPostsViewController : AbstractPostsViewController <ReaderPostContentViewDelegate>

- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;

@end
