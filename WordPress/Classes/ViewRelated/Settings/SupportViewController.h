#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SupportViewController : UITableViewController <MFMailComposeViewControllerDelegate>

+ (void)checkIfFeedbackShouldBeEnabled;
+ (void)showFromTabBar;

@end
