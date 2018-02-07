#import "WPStyleGuide+Stats.h"
#import <WordPressShared/WPFontManager.h>

const CGFloat StatsVCHorizontalOuterPadding = 8.0f;
const CGFloat StatsVCVerticalOuterPadding = 16.0f;

@implementation WPStyleGuide (Stats)

+ (UIFont *)axisLabelFont {
    return [WPFontManager systemRegularFontOfSize:12.0];
}


+ (UIFont *)axisLabelFontSmaller
{
    return [[self axisLabelFont] fontWithSize:8.0f];
}


+ (UIColor *)statsLighterOrange
{
    return [UIColor colorWithRed:0.965 green:0.718 blue:0.494 alpha:1]; /*#f6b77e*/
}


+ (UIColor *)statsLighterOrangeTransparent
{
    return [UIColor colorWithRed:0.965 green:0.718 blue:0.494 alpha:0.3]; /*#f6b77e*/
}


+ (UIColor *)statsMediumBlue
{
    return [UIColor colorWithRed:0 green:0.667 blue:0.863 alpha:1]; /*#00aadc*/
}


+ (UIColor *)statsMediumGray
{
    return [UIColor colorWithRed:0.824 green:0.871 blue:0.902 alpha:1]; /*#d2dee6*/
}


+ (UIColor *)statsDarkerOrange
{
    return [self jazzyOrange];
}


+ (UIColor *)statsDarkGray
{
    return [UIColor colorWithRed:0.196 green:0.255 blue:0.333 alpha:1]; /*#324155*/
}

+ (UIColor *)statsLessDarkGrey
{
    return [UIColor colorWithRed:0.345 green:0.447 blue:0.584 alpha:1]; /*#587295*/
}


+ (UIColor *)statsLightGray
{
    return [UIColor colorWithRed:0.91 green:0.941 blue:0.961 alpha:1]; /*#e8f0f5*/
}


+ (UIColor *)statsLightGrayZeroValue
{
    return [UIColor colorWithRed:0.576 green:0.651 blue:0.753 alpha:1]; /*#93a6c0*/
}


+ (UIColor *)statsNestedCellBackground
{
    // AKA Calypso $gray-light
    return [UIColor colorWithRed:0.953 green:0.965 blue:0.973 alpha:1]; /*#f3f6f8*/
}


+ (UIColor *)statsUltraLightGray
{
    return [UIColor colorWithRed:0.957 green:0.973 blue:0.98 alpha:1]; /*#f4f8fa*/
}

+ (UIColor *)statsPostActivityLevel1CellBackground
{
    // Default grey #c8d7e1
    return [UIColor colorWithRed:0.784 green:0.843 blue:0.882 alpha:1];
}

+ (UIColor *)statsPostActivityLevel2CellBackground
{
    // #91e2fb
    return [UIColor colorWithRed:0.569 green:0.886 blue:0.984 alpha:1];
}

+ (UIColor *)statsPostActivityLevel3CellBackground
{
    // #00bef6
    return [UIColor colorWithRed:0 green:0.745 blue:0.965 alpha:1];
}

+ (UIColor *)statsPostActivityLevel4CellBackground
{
    // #0083a9
    return [UIColor colorWithRed:0 green:0.514 blue:0.663 alpha:1];
}

+ (UIColor *)statsPostActivityLevel5CellBackground
{
    // #003443
    return [UIColor colorWithRed:0 green:0.204 blue:0.263 alpha:1];
}

@end
