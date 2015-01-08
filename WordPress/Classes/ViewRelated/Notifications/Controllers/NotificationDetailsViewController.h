#import <UIKit/UIKit.h>



@class Notification;

@interface NotificationDetailsViewController : UIViewController <UIViewControllerRestoration>
- (void)setupWithNotification:(Notification *)notification;
@end
