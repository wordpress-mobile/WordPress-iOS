#import <Foundation/Foundation.h>

@interface WPActivityDefaults : NSObject
+ (NSArray *)defaultActivities;
+ (void)trackActivityType:(NSString *)activityType withPrefix:(NSString *)prefix;
@end
