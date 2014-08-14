#import <UIKit/UIKit.h>



@class Notification;

@interface NotificationDetailsViewController : UITableViewController <UIViewControllerRestoration>
@property (nonatomic, strong, readwrite) Notification *note;
@end
