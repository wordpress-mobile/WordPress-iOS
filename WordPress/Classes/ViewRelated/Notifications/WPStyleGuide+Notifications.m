#import "WPStyleGuide+Notifications.h"
#import "WPFontManager.h"



#pragma mark ====================================================================================
#pragma mark WPStyleGuide+Notifications
#pragma mark ====================================================================================

@implementation WPStyleGuide (Notifications)

// Noticon Styles
//
+ (UIFont *)notificationIconFont
{
    return [UIFont fontWithName:@"Noticons" size:16.0];
}

+ (UIColor *)notificationIconReadColor
{
    return [UIColor colorWithRed:0xA4/255.0 green:0xB9/255.0 blue:0xC9/255.0 alpha:0xFF/255.0];
}

+ (UIColor *)notificationIconUnreadColor
{
    return [UIColor colorWithRed:0x25/255.0 green:0x9C/255.0 blue:0xCF/255.0 alpha:0xFF/255.0]/* 259CCFFF */;
}


// Notification Cell
//
+ (UIColor *)notificationBackgroundReadColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)notificationBackgroundUnreadColor
{
    return [UIColor colorWithRed:0xF1/255.0 green:0xF6/255.0 blue:0xF9/255.0 alpha:0xFF/255.0];/* F1F6F9FF */
}


// Notification Timestamp
//
+ (UIFont *)notificationTimestampFont
{
    return [WPFontManager openSansRegularFontOfSize:14.0f];
}

+ (UIColor *)notificationTimestampTextColor
{
    return [UIColor colorWithRed:0xB7/255.0 green:0xC9/255.0 blue:0xD5/255.0 alpha:0xFF/255.0]; /* B7C9D5FF */
}



// Notification Subject
//
+ (UIFont *)notificationSubjectFontRegular
{
    return [WPFontManager openSansRegularFontOfSize:14.0f];
}

+ (UIFont *)notificationSubjectFontBold
{
    return [WPFontManager openSansBoldFontOfSize:14.0f];
}

+ (UIFont *)notificationSubjectFontItalics
{
    return [WPFontManager openSansItalicFontOfSize:14.0f];
}

+ (NSParagraphStyle *)notificationSubjectParagraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return paragraphStyle;
}

+ (NSDictionary *)notificationSubjectAttributesRegular
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationSubjectParagraphStyle],
        NSFontAttributeName             : [self notificationSubjectFontRegular]
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



// Notification Header styles
//
+ (UIColor *)notificationHeaderTextColor
{
    return [self notificationIconReadColor];
}

+ (UIColor *)notificationHeaderBackgroundColor
{
    return [UIColor whiteColor];
}

+ (UIFont *)notificationHeaderIconFont
{
    return [UIFont fontWithName:@"Noticons" size:20.0];
}



// Notification Block: Regular
//
+ (UIColor *)notificationBlockBackgroundColor
{
    return [UIColor clearColor];
}

+ (UIFont *)notificationBlockFontRegular
{
    CGFloat size = (IS_IPAD ? 18.0f : 16.0f);
    return [WPFontManager openSansRegularFontOfSize:size];
}

+ (UIFont *)notificationBlockFontBold
{
    CGFloat size = (IS_IPAD ? 18.0f : 16.0f);
    return [WPFontManager openSansBoldFontOfSize:size];
}

+ (UIFont *)notificationBlockFontItalics
{
    CGFloat size = (IS_IPAD ? 18.0f : 16.0f);
    return [WPFontManager openSansItalicFontOfSize:size];
}

+ (NSParagraphStyle *)notificationBlockParagraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 24;
    paragraphStyle.maximumLineHeight = 24;
    return paragraphStyle;
}

+ (NSDictionary *)notificationBlockAttributesRegular
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationBlockParagraphStyle],
        NSFontAttributeName             : [WPStyleGuide notificationBlockFontRegular],
        NSForegroundColorAttributeName  : [WPStyleGuide littleEddieGrey],
    };
}

+ (NSDictionary *)notificationBlockAttributesBold
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationBlockParagraphStyle],
        NSFontAttributeName             : [WPStyleGuide notificationBlockFontBold],
        NSForegroundColorAttributeName  : [WPStyleGuide littleEddieGrey],
    };
}

+ (NSDictionary *)notificationBlockAttributesItalics
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationBlockParagraphStyle],
        NSFontAttributeName             : [WPStyleGuide notificationBlockFontItalics],
        NSForegroundColorAttributeName  : [WPStyleGuide littleEddieGrey],
    };
}



// Notification Block: Quoted
//
+ (NSDictionary *)notificationQuotedAttributesItalics
{
    return @{
        NSParagraphStyleAttributeName   : [self notificationBlockParagraphStyle],
        NSFontAttributeName             : [WPStyleGuide notificationBlockFontItalics],
        NSForegroundColorAttributeName  : [WPStyleGuide allTAllShadeGrey],
    };
}

@end
