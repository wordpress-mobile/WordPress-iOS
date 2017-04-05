#import "WPNavigationMediaPickerViewController+StatusBarStyle.h"

@implementation WPNavigationMediaPickerViewController (StatusBarStyle)

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
