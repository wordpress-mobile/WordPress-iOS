#import "WPStyleGuide+Notifications.h"



@implementation WPStyleGuide (Notifications)

+ (UIFont *)notificationIconFont
{
    return [UIFont fontWithName:@"Noticons" size:16.0];
}

+ (UIColor *)notificationIconColor
{
    return [UIColor colorWithRed:0xA4/255.0 green:0xB9/255.0 blue:0xC9/255.0 alpha:0xFF/255.0];
}

+ (UIColor *)notificationSubjectTextColor
{
    return [[self class] notificationIconColor];
}

+ (UIColor *)notificationSubjectBackgroundColor
{
    return [UIColor whiteColor];
}

+ (UIFont *)notificationSubjectFont
{
    return [UIFont fontWithName:@"OpenSans" size:14.0];
}

+ (UIFont *)notificationSubjectFontBold
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:14.0];
}

+ (UIFont *)notificationSubjectFontItalics
{
    return [UIFont fontWithName:@"OpenSans-Italic" size:14.0];
}

+ (NSParagraphStyle *)notificationSubjectParagraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return paragraphStyle;
}

+ (NSDictionary *)notificationSubjectAttributes
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationSubjectParagraphStyle],
        NSFontAttributeName             : [self notificationSubjectFont]
    };
}

+ (NSDictionary *)notificationSubjectAttributesBold
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationSubjectParagraphStyle],
        NSFontAttributeName             : [self notificationSubjectFontBold]
    };
}

+ (NSDictionary *)notificationSubjectAttributesItalics
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationSubjectParagraphStyle],
        NSFontAttributeName             : [self notificationSubjectFontItalics]
    };
}



+ (UIFont *)notificationBlockIconFont
{
    return [UIFont fontWithName:@"Noticons" size:20.0];
}

+ (UIColor *)notificationBlockIconColor
{
    return [self notificationIconColor];
}

+ (UIColor *)notificationBlockBackgroundColor
{
    return [UIColor clearColor];
}

+ (UIFont *)notificationBlockFont
{
    CGFloat size = (IS_IPAD ? 18.0f : 16.0f);
    return [UIFont fontWithName:@"OpenSans" size:size];
}

+ (UIFont *)notificationBlockFontBold
{
    CGFloat size = (IS_IPAD ? 18.0f : 16.0f);
    return [UIFont fontWithName:@"OpenSans-Bold" size:size];
}

+ (NSDictionary *)notificationBlockAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight        = 24;
    paragraphStyle.maximumLineHeight        = 24;
    
    return @{
        NSParagraphStyleAttributeName   : paragraphStyle,
        NSFontAttributeName             : [WPStyleGuide notificationBlockFont],
        NSForegroundColorAttributeName  : [WPStyleGuide littleEddieGrey],
    };
}

+ (NSDictionary *)notificationBlockAttributesBold
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight        = 24;
    paragraphStyle.maximumLineHeight        = 24;
    
    return @{
        NSParagraphStyleAttributeName   : paragraphStyle,
        NSFontAttributeName             : [WPStyleGuide notificationBlockFontBold],
        NSForegroundColorAttributeName  : [WPStyleGuide littleEddieGrey],
    };
}

@end
