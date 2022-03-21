#import "UIViewController+RemoveQuickStart.h"

#import "Blog.h"
#import "WordPress-Swift.h"

@implementation UIViewController (RemoveQuickStart)

- (void)removeQuickStartFromBlog:(Blog *)blog
{
    [NoticesDispatch lock];
    NSString *removeTitle = NSLocalizedString(@"Remove Next Steps", @"Title for action that will remove the next steps/quick start menus.");
    NSString *removeMessage = NSLocalizedString(@"Removing Next Steps will hide all tours on this site. This action cannot be undone.", @"Explanation of what will happen if the user confirms this alert.");
    NSString *confirmationTitle = NSLocalizedString(@"Remove", @"Title for button that will confirm removing the next steps/quick start menus.");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel button");

    UIAlertController *removeConfirmation = [UIAlertController alertControllerWithTitle:removeTitle message:removeMessage preferredStyle:UIAlertControllerStyleAlert];
    [removeConfirmation addCancelActionWithTitle:cancelTitle handler:^(UIAlertAction * _Nonnull action) {
        [WPAnalytics track:WPAnalyticsStatQuickStartRemoveDialogButtonCancelTapped];
        [NoticesDispatch unlock];
    }];
    [removeConfirmation addDefaultActionWithTitle:confirmationTitle handler:^(UIAlertAction * _Nonnull action) {
        [WPAnalytics track:WPAnalyticsStatQuickStartRemoveDialogButtonRemoveTapped];
        [[QuickStartTourGuide shared] removeFrom:blog];
        [NoticesDispatch unlock];
    }];

    UIAlertController *removeSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [removeSheet addDestructiveActionWithTitle:removeTitle handler:^(UIAlertAction * _Nonnull action) {
        [self presentViewController:removeConfirmation animated:YES completion:nil];
    }];
    [removeSheet addCancelActionWithTitle:cancelTitle handler:^(UIAlertAction * _Nonnull action) {
        [NoticesDispatch unlock];
    }];

    [self presentViewController:removeSheet animated:YES completion:nil];
}

@end
