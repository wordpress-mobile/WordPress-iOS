#import "MFMessageComposeViewController+StatusBarStyle.h"

@implementation MFMessageComposeViewController (StatusBarStyle)

#pragma mark - Status bar management

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

@end
