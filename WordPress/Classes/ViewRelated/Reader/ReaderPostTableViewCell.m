#import "ReaderPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "ReaderPost.h"
#import "ReaderPostContentView.h"

@implementation ReaderPostTableViewCell

#pragma mark - Private Methods

- (WPContentViewBase *)configurePostView {
    ReaderPostContentView *postView = [[ReaderPostContentView alloc] init];
    postView.translatesAutoresizingMaskIntoConstraints = NO;
    postView.backgroundColor = [UIColor whiteColor];
    return postView;
}

#pragma mark - Instance Methods

- (void)configureCell:(ReaderPost *)post
{
	self.post = post;
    if ([self.postView isKindOfClass:[ReaderPostContentView class]]) {
        [(ReaderPostContentView *)self.postView configurePost:post];
    }
}

@end
