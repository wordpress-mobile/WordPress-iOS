#import <UIKit/UIKit.h>
#import "WPTableViewController.h"



@interface NotificationsViewController : WPTableViewController

#warning TODO: Verify this in New Model
- (void)showDetailsForNoteWithID:(NSString *)notificationID animated:(BOOL)animated;

@end
