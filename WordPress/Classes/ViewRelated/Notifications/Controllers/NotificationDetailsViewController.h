#import <UIKit/UIKit.h>



@class Notification;
typedef void (^NotificationDetailsCallbackBlock)();


@interface NotificationDetailsViewController : UIViewController <UIViewControllerRestoration>

/**
 *	@brief		This block will be called whenever a destructive action is performed over a Notification object.
 */

@property (nonatomic, copy) NotificationDetailsCallbackBlock onDestructionCallback;

/**
 *	@brief		This method renders the details view, for any given notification/
 *  @details    You should only call this method once. It will take care of attaching any required subviews,
 *              in order to properly render the Notification's details.
 *
 *	@param		notification    The Notification to display.
 */
- (void)setupWithNotification:(Notification *)notification;

@end
