#import "WPStyleGuide.h"
#import "WPTextFieldTableViewCell.h"
#import "WPFontManager.h"
#import "WPDeviceIdentification.h"

// A workaround to make the Swift extension defined in WordPressSharedView target visible to this file here.
@interface WPStyleGuide (SwiftExtension)

+ (CGFloat)maxFontSize;
+ (UIFont *)fontForTextStyle:(UIFontTextStyle)style maximumPointSize:(CGFloat)pointSize;

@end

@implementation WPStyleGuide

#pragma mark - Fonts and Text

+ (UIFont *)subtitleFont
{
    CGFloat maximumPointSize = [WPStyleGuide maxFontSize];
    return [self fontForTextStyle:UIFontTextStyleCaption1 maximumPointSize: maximumPointSize];
}

+ (NSDictionary *)subtitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self subtitleFont]};
}

+ (UIFont *)subtitleFontItalic
{
    return [UIFont italicSystemFontOfSize:[[self subtitleFont] pointSize]];
}

+ (NSDictionary *)subtitleItalicAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self subtitleFontItalic]};
}

+ (UIFont *)subtitleFontBold
{
    return [UIFont systemFontOfSize:[[self subtitleFont] pointSize] weight:UIFontWeightBold];
}

+ (NSDictionary *)subtitleAttributesBold
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self subtitleFontBold]};
}

+ (UIFont *)labelFont
{
    return [UIFont systemFontOfSize:[[self labelFontNormal] pointSize] weight:UIFontWeightBold];
}

+ (UIFont *)labelFontNormal
{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
}

+ (NSDictionary *)labelAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 12;
    paragraphStyle.maximumLineHeight = 12;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self labelFont]};
}

+ (UIFont *)regularTextFont
{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
}

+ (UIFont *)regularTextFontSemiBold
{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

+ (NSDictionary *)regularTextAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 24;
    paragraphStyle.maximumLineHeight = 24;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self regularTextFont]};
}

+ (UIFont *)tableviewTextFont
{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
}

+ (UIFont *)tableviewSubtitleFont
{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
}

+ (UIFont *)tableviewSectionHeaderFont
{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}

+ (UIFont *)tableviewSectionFooterFont
{
	return [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}


#pragma mark - Colors
// https://wordpress.com/design-handbook/colors/

+ (UIColor *)colorWithR:(NSInteger)red G:(NSInteger)green B:(NSInteger)blue alpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:(CGFloat)red/255.0 green:(CGFloat)green/255.0 blue:(CGFloat)blue/255.0 alpha:alpha];
}


#pragma mark - Blues

+ (UIColor *)wordPressBlue
{
    return [self colorWithR:0 G:135 B:190 alpha:1.0];
}

+ (UIColor *)lightBlue
{
    return [self colorWithR:120 G:220 B:250 alpha:1.0];
}

+ (UIColor *)mediumBlue
{
    return [self colorWithR:0 G:170 B:220 alpha:1.0];
}

+ (UIColor *)darkBlue
{
    return [self colorWithR:0 G:80 B:130 alpha:1.0];
}


#pragma mark - Greys

+ (UIColor *)grey
{
    return [self colorWithR:135 G:166 B:188 alpha:1.0];
}

+ (UIColor *)lightGrey
{
    return [self colorWithR:243 G:246 B:248 alpha:1.0];
}

+ (UIColor *)greyLighten30
{
    return [self colorWithR:233 G:239 B:243 alpha:1.0];
}

+ (UIColor *)greyLighten20
{
    return [self colorWithR:200 G:215 B:225 alpha:1.0];
}

+ (UIColor *)greyLighten10
{
    return [self colorWithR:168 G:190 B:206 alpha:1.0];
}

+ (UIColor *)greyDarken10
{
    return [self colorWithR:102 G:142 B:170 alpha:1.0];
}

+ (UIColor *)greyDarken20
{
    return [self colorWithR:79 G:116 B:142 alpha:1.0];
}

+ (UIColor *)greyDarken30
{
    return [self colorWithR:61 G:89 B:109 alpha:1.0];
}

+ (UIColor *)darkGrey
{
    return [self colorWithR:46 G:68 B:83 alpha:1.0];
}


#pragma mark - Oranges

+ (UIColor *)jazzyOrange
{
    return [self colorWithR:240 G:130 B:30 alpha:1.0];
}

#pragma mark - Validations / Alerts

+ (UIColor *)errorRed
{
    return [self colorWithR:217 G:79 B:79 alpha:1.0];
}

#pragma mark - Bar styles

+ (UIBarButtonItemStyle)barButtonStyleForDone
{
    return UIBarButtonItemStylePlain;
}

+ (UIBarButtonItemStyle)barButtonStyleForBordered
{
    return UIBarButtonItemStylePlain;
}

+ (void)setRightBarButtonItemWithCorrectSpacing:(UIBarButtonItem *)barButtonItem forNavigationItem:(UINavigationItem *)navigationItem
{
    navigationItem.rightBarButtonItems = @[[self spacerForNavigationBarButtonItems], barButtonItem];
}

+ (UIBarButtonItem *)spacerForNavigationBarButtonItems
{
    UIBarButtonItem *spacerButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerButton.width = -16.0;
    return spacerButton;
}

#pragma mark - Deprecated Colors

+ (UIColor *)newKidOnTheBlockBlue __deprecated
{
    return [self mediumBlue];
}

+ (UIColor *)midnightBlue __deprecated
{
    return [self darkBlue];
}

@end
