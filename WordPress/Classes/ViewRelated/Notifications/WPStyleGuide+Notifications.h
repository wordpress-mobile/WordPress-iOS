#import "WPStyleGuide.h"



#pragma mark ====================================================================================
#pragma mark WPStyleGuide+Notifications
#pragma mark ====================================================================================

@interface WPStyleGuide (Notifications)

// Notification Icon
+ (UIFont *)notificationIconFont;
+ (UIColor *)notificationIconReadColor;
+ (UIColor *)notificationIconUnreadColor;

// Notification Cell
+ (UIColor *)notificationBackgroundReadColor;
+ (UIColor *)notificationBackgroundUnreadColor;

// Notification Timestamp
+ (UIFont *)notificationTimestampFont;
+ (UIColor *)notificationTimestampTextColor;

// Notification Subject
+ (UIFont *)notificationSubjectFontRegular;
+ (UIFont *)notificationSubjectFontBold;
+ (UIFont *)notificationSubjectFontItalics;
+ (NSDictionary *)notificationSubjectAttributesRegular;
+ (NSDictionary *)notificationSubjectAttributesBold;
+ (NSDictionary *)notificationSubjectAttributesItalics;

// Notification Header
+ (UIColor *)notificationHeaderTextColor;
+ (UIColor *)notificationHeaderBackgroundColor;
+ (UIFont *)notificationHeaderIconFont;

// Notification Blocks: Regular
+ (UIColor *)notificationBlockBackgroundColor;
+ (UIFont *)notificationBlockFontRegular;
+ (UIFont *)notificationBlockFontBold;
+ (UIFont *)notificationBlockFontItalics;
+ (NSDictionary *)notificationBlockAttributesRegular;
+ (NSDictionary *)notificationBlockAttributesBold;
+ (NSDictionary *)notificationBlockAttributesItalics;

// Notification Blocks: Quoted
+ (NSDictionary *)notificationQuotedAttributesItalics;

@end
