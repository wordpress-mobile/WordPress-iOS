#import "LocalNotificationsManager.h"

NSTimeInterval const oneDayInSeconds = 60 * 60 * 24;

@implementation LocalNotificationsManager

- (void)clearAndScheduleLocalReadItLaterNotification
{
    [self clearAllNotifications];
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    localNotification.fireDate = [self oneDayFromNow];
    localNotification.alertTitle = @"WordPress";
    localNotification.alertBody = NSLocalizedString(@"Read it later!", @"Notification body for their Read It Later");
}

- (void)clearAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (NSDate *)oneDayFromNow
{
    NSDate *now = [[NSDate alloc] init];
    
    return [[NSDate alloc] initWithTimeInterval:oneDayInSeconds sinceDate:now];
}

@end
