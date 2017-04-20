#import <SVProgressHUD/SVProgressHUD.h>

@interface SVProgressHUD (Dismiss)

+ (void)showDismissableErrorWithStatus:(NSString*)status;
+ (void)showDismissableSuccessWithStatus:(NSString*)status;

@end
