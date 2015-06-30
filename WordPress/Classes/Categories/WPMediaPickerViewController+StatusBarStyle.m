#import "WPMediaPickerViewController+StatusBarStyle.h"

@implementation WPMediaPickerViewController (StatusBarStyle)

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
