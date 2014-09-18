#import "EditReplyViewController.h"
#import "EditCommentViewController+Internals.h"



@interface EditReplyViewController ()

@end

@implementation EditReplyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Edit Reply", @"");
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Send", @"");
    self.content = [NSString string];
}


#pragma mark - Helper Methods

- (void)finishWithUpdates
{
    if ([self.replyDelegate respondsToSelector:@selector(editReplyViewController:didFinishWithContent:)]) {
        [self.replyDelegate editReplyViewController:self didFinishWithContent:self.textView.text];
    }
}

- (void)finishWithoutUpdates
{
    if ([self.replyDelegate respondsToSelector:@selector(editReplyViewControllerFinished:)]) {
        [self.replyDelegate editReplyViewControllerFinished:self];
    }
}

@end
