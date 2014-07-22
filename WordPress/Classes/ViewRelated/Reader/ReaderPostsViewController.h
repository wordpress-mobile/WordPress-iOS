#import <UIKit/UIKit.h>
#import "AbstractPostsViewController.h"
#import "ReaderPostContentView.h"

@interface ReaderPostsViewController : AbstractPostsViewController <ReaderPostContentViewDelegate>

- (void)openPost:(NSUInteger*)postId onBlog:(NSUInteger)blogId;

@end
