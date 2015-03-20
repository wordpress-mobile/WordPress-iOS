#import <Foundation/Foundation.h>

@interface LocalNotificationsManager : NSObject

- (void)clearAndScheduleLocalReadItLaterNotification;
- (void)clearAllNotifications;

@end
