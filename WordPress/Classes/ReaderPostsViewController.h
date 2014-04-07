#import <UIKit/UIKit.h>
#import "WPTableViewController.h"
#import "ReaderPostView.h"

extern NSString * const ReaderTopicDidChangeNotification;

@interface ReaderPostsViewController : WPTableViewController<ReaderPostViewDelegate>

- (void)openPost:(NSUInteger*)postId onBlog:(NSUInteger)blogId;

@end
