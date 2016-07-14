#import <UIKit/UIKit.h>
#import "Notifications+Definitions.h"



/**
 *  @class      NotificationsViewController
 *  @brief      The purpose of this class is to render the collection of Notifications, associated to the main
 *              WordPress.com account found in the system.
 *  @details    This class relies on both, Simperium and WPTableViewHandler to automatically receive
 *              new Notifications that might be generated, and render them onscreen.
 *              Plus, we provide a simple mechanism to render the details for a specific Notification,
 *              given its remote identifier. This is specially useful when dealing with events derived from
 *              interactions with Push Notifications OS banners.
 */

@interface NotificationsViewController : UITableViewController



@end
