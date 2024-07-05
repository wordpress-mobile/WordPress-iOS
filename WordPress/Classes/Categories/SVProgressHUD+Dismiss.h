@import SVProgressHUD;

@interface SVProgressHUD (Dismiss)

+ (void)showDismissibleErrorWithStatus:(NSString *)status;
+ (void)showDismissibleSuccessWithStatus:(NSString *)status;

@end
