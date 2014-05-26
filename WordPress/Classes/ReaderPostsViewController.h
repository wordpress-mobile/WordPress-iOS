#import <UIKit/UIKit.h>
#import "WPTableViewController.h"
#import "ReaderPostView.h"

@interface ReaderPostsViewController : WPTableViewController<ReaderPostViewDelegate>

- (void)openPost:(NSUInteger*)postId onBlog:(NSUInteger)blogId;

@end
