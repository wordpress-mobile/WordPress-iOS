#import <UIKit/UIKit.h>

typedef NSString * SupportSourceTag NS_EXTENSIBLE_STRING_ENUM;
extern SupportSourceTag const SupportSourceTagWPComLogin;
extern SupportSourceTag const SupportSourceTagWPComSignup;
extern SupportSourceTag const SupportSourceTagWPOrgLogin;
extern SupportSourceTag const SupportSourceTagJetpackLogin;
extern SupportSourceTag const SupportSourceTagGeneralLogin;
extern SupportSourceTag const SupportSourceTagInAppFeedback;
extern SupportSourceTag const SupportSourceTagAztecFeedback;
extern SupportSourceTag const SupportSourceTagLoginEmail;
extern SupportSourceTag const SupportSourceTagLoginMagicLink;
extern SupportSourceTag const SupportSourceTagLoginWPComPassword;
extern SupportSourceTag const SupportSourceTagLogin2FA;
extern SupportSourceTag const SupportSourceTagLoginSiteAddress;
extern SupportSourceTag const SupportSourceTagLoginUsernamePassword;
extern SupportSourceTag const SupportSourceTagWPComCreateSiteCategory;
extern SupportSourceTag const SupportSourceTagWPComCreateSiteTheme;

@interface SupportViewController : UITableViewController
@property (nonatomic, strong) SupportSourceTag sourceTag;
@property (nonatomic, strong) NSDictionary *helpshiftOptions;

- (void)showFromTabBar;

@end
