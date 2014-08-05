#import <UIKit/UIKit.h>
#import "WPTableViewController.h"
#import "ReaderPostContentView.h"

@interface ReaderPostsViewController : WPTableViewController<ReaderPostContentViewDelegate>

- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;

@end
