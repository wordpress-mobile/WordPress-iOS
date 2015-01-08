#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Helpshift/Helpshift.h>

@interface SupportViewController : UITableViewController <MFMailComposeViewControllerDelegate, HelpshiftDelegate>

+ (void)checkIfFeedbackShouldBeEnabled;
+ (BOOL)isHelpshiftEnabled;
+ (void)showFromTabBar;

@end
