#import <UIKit/UIKit.h>
#import "ReaderPostContentView.h"

@interface ReaderPostsViewController : UITableViewController<ReaderPostContentViewDelegate, UIViewControllerRestoration>

- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;

@end
