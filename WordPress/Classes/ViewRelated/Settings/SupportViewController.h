#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Helpshift/Helpshift.h>

@interface SupportViewController : UITableViewController <MFMailComposeViewControllerDelegate, HelpshiftDelegate>

+ (void)checkIfFeedbackShouldBeEnabled;
+ (void)checkIfHelpshiftShouldBeEnabled;
+ (BOOL)isHelpshiftEnabled;
+ (void)showFromTabBar;

@end
