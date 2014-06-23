#import <UIKit/UIKit.h>
#import "WPTableViewController.h"
#import "ReaderPostContentView.h"

@interface ReaderPostsViewController : WPTableViewController<ReaderPostContentViewDelegate>

- (void)openPost:(NSUInteger*)postId onBlog:(NSUInteger)blogId;

@end
