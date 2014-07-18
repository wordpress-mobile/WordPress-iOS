#import "ReaderPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "ReaderPost.h"
#import "ReaderPostContentView.h"

@implementation ReaderPostTableViewCell

+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview
{
    UIView *view = subview;
	while (![view isKindOfClass:self]) {
		view = (UIView *)view.superview;
	}
    
    if (view == subview)
        return nil;
    
    return (ReaderPostTableViewCell *)view;
}


#pragma mark - Lifecycle Methods

- (void)dealloc
{
	self.post = nil;
}

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
    [(ReaderPostContentView *)self.postView configurePost:post];
}

@end
