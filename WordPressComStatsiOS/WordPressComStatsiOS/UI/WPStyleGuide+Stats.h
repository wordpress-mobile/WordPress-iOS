@import WordPressShared;

extern const CGFloat StatsVCHorizontalOuterPadding;
extern const CGFloat StatsCVerticalOuterPadding;

@interface WPStyleGuide (Stats)

+ (UIFont *)axisLabelFont;
+ (UIFont *)axisLabelFontSmaller;

+ (UIColor *)statsLighterOrangeTransparent;
+ (UIColor *)statsLighterOrange;
+ (UIColor *)statsDarkerOrange;

+ (UIColor *)statsMediumBlue;
+ (UIColor *)statsMediumGray;
+ (UIColor *)statsLightGray;
+ (UIColor *)statsUltraLightGray;
+ (UIColor *)statsDarkGray;
+ (UIColor *)statsLessDarkGrey;
+ (UIColor *)statsLightGrayZeroValue;

+ (UIColor *)statsNestedCellBackground;

+ (UIColor *)statsPostActivityLevel1CellBackground;
+ (UIColor *)statsPostActivityLevel2CellBackground;
+ (UIColor *)statsPostActivityLevel3CellBackground;
+ (UIColor *)statsPostActivityLevel4CellBackground;
+ (UIColor *)statsPostActivityLevel5CellBackground;

@end
