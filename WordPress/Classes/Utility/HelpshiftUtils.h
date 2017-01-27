#import <Foundation/Foundation.h>

extern NSString *const UserDefaultsHelpshiftWasUsed;
extern NSString *const HelpshiftUnreadCountUpdatedNotification;

@class WPAccount;

@interface HelpshiftUtils : NSObject

+ (void)setup;
+ (BOOL)isHelpshiftEnabled;
+ (NSInteger)unreadNotificationCount;
+ (void)refreshUnreadNotificationCount;
+ (NSArray<NSString *> *)planTagsForAccount:(WPAccount *)account;

+ (NSDictionary<NSString *, NSObject *> *)helpshiftMetadataWithTags:(NSArray<NSString *> *)extraTags;

@end
