#import "NotificationsManager+TestHelper.h"


static NSString *const NotificationsDeviceToken = @"apnsDeviceToken";


@implementation NotificationsManager (TestHelper)

+ (void)setDummyDeviceToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"aFakeAPNSToken" forKey:NotificationsDeviceToken];
    [defaults synchronize];
}

+ (void)removeDummyDeviceToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:NotificationsDeviceToken];
    [defaults synchronize];
}

@end
