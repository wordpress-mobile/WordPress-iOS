#import <Foundation/Foundation.h>

extern NSString *const UserDefaultsHelpshiftWasUsed;
extern NSString *const HelpshiftUnreadCountUpdatedNotification;

@interface HelpshiftUtils : NSObject

+ (void)setup;
+ (BOOL)isHelpshiftEnabled;
+ (NSInteger)unreadNotificationCount;
+ (void)refreshUnreadNotificationCount;

@end
