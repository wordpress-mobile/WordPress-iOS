#import <Foundation/Foundation.h>
#import "RemoteNotificationsManager.h"


@interface RemoteNotificationsManager (TestHelper)

+ (void)setDummyDeviceToken;
+ (void)removeDummyDeviceToken;

@end
