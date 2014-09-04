#import <UIKit/UIKit.h>



@class Notification;

@interface NotificationDetailsViewController : UIViewController <UIViewControllerRestoration>
@property (nonatomic, strong, readwrite) Notification *note;
@end
