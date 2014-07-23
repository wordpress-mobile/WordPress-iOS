#import "WPStyleGuide.h"



@interface WPStyleGuide (Notifications)

+ (UIFont *)notificationIconFont;
+ (UIColor *)notificationIconColor;

+ (UIColor *)notificationSubjectTextColor;
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
+ (UIFont *)notificationBlockFontItalics;
+ (NSDictionary *)notificationBlockAttributes;
+ (NSDictionary *)notificationBlockAttributesBold;
+ (NSDictionary *)notificationBlockAttributesItalics;

@end
