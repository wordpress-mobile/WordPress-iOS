#import "WPStyleGuide.h"



@interface WPStyleGuide (Notifications)

+ (UIFont *)notificationIconFont;
+ (UIColor *)notificationIconColor;

+ (UIColor *)notificationSubjectBackgroundColor;
+ (UIFont *)notificationSubjectFont;
+ (UIFont *)notificationSubjectFontBold;
+ (UIFont *)notificationSubjectFontItalics;
+ (NSDictionary *)notificationSubjectAttributes;
+ (NSDictionary *)notificationSubjectAttributesBold;
+ (NSDictionary *)notificationSubjectAttributesItalics;

+ (UIFont *)notificationBlockIconFont;
+ (UIColor *)notificationBlockIconColor;
+ (UIColor *)notificationBlockBackgroundColor;
+ (UIFont *)notificationBlockFont;
+ (UIFont *)notificationBlockFontBold;
+ (NSDictionary *)notificationBlockAttributes;
+ (NSDictionary *)notificationBlockAttributesBold;

@end
