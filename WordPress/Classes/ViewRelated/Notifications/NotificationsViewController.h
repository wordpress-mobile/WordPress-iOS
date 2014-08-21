#import <UIKit/UIKit.h>
#import "WPTableViewController.h"



@interface NotificationsViewController : WPTableViewController

- (void)showDetailsForNoteWithID:(NSString *)notificationID animated:(BOOL)animated;

@end
