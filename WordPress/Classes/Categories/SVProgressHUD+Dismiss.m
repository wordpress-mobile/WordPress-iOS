#import "SVProgressHUD+Dismiss.h"

@implementation SVProgressHUD (Dismiss)

+ (void)showDismissibleErrorWithStatus:(NSString *)status
{
    [SVProgressHUD registerForHUDNotifications];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showErrorWithStatus:status];
}

+ (void)showDismissibleSuccessWithStatus:(NSString *)status
{
    [SVProgressHUD registerForHUDNotifications];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showSuccessWithStatus:status];
}

#pragma mark - NSNotificationCenter

+ (void)handleHUDTappedNotification:(NSNotification *)notification
{
    [SVProgressHUD dismiss];
}

+ (void)handleHUDDisappearedNotification:(NSNotification *)notification
{
    [self unregisterFromHUDNotifications];
}

+ (void)registerForHUDNotifications
{
    // Remove the observer from NSNotificationCenter to prevent having duplicate entries
    // when the HUD is re-displayed before being dismissed
    [self unregisterFromHUDNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleHUDTappedNotification:)
                                                 name:SVProgressHUDDidReceiveTouchEventNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleHUDDisappearedNotification:)
                                                 name:SVProgressHUDWillDisappearNotification
                                               object:nil];
}

+ (void)unregisterFromHUDNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SVProgressHUDDidReceiveTouchEventNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SVProgressHUDWillDisappearNotification
                                                  object:nil];
}

@end
