#import "UIViewController+RemoveQuickStart.h"

#import "Blog.h"
#import "WordPress-Swift.h"

@implementation UIViewController (RemoveQuickStart)

- (void)removeQuickStartFromBlog:(Blog *)blog sourceView:(UIView *)sourceView sourceRect:(CGRect)sourceRect
{
    [NoticesDispatch lock];
    NSString *removeTitle = NSLocalizedString(@"Remove Next Steps", @"Title for action that will remove the next steps/quick start menus.");
    NSString *removeMessage = NSLocalizedString(@"Removing Next Steps will hide all tours on this site. This action cannot be undone.", @"Explanation of what will happen if the user confirms this alert.");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel button");

    UIAlertController *removeSheet = [UIAlertController alertControllerWithTitle:removeTitle message:removeMessage preferredStyle:UIAlertControllerStyleActionSheet];
    removeSheet.popoverPresentationController.sourceView = sourceView;
    removeSheet.popoverPresentationController.sourceRect = sourceRect;
    [removeSheet addDestructiveActionWithTitle:removeTitle handler:^(UIAlertAction * _Nonnull __unused action) {
        [WPAnalytics trackQuickStartStat:WPAnalyticsStatQuickStartRemoveDialogButtonRemoveTapped blog: blog];
        [[QuickStartTourGuide shared] removeFrom:blog];
        [NoticesDispatch unlock];
    }];
    [removeSheet addCancelActionWithTitle:cancelTitle handler:^(UIAlertAction * _Nonnull __unused action) {
        [WPAnalytics trackQuickStartStat:WPAnalyticsStatQuickStartRemoveDialogButtonCancelTapped blog: blog];
        [NoticesDispatch unlock];
    }];

    [self presentViewController:removeSheet animated:YES completion:nil];
}

@end
