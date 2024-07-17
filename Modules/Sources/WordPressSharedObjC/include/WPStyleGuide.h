#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class WPTextFieldTableViewCell;
@interface WPStyleGuide : NSObject

// Fonts
+ (UIFont *)subtitleFont;
+ (NSDictionary *)subtitleAttributes;
+ (UIFont *)subtitleFontItalic;
+ (NSDictionary *)subtitleItalicAttributes;
+ (UIFont *)subtitleFontBold;
+ (NSDictionary *)subtitleAttributesBold;
+ (UIFont *)labelFont;
+ (UIFont *)labelFontNormal;
+ (NSDictionary *)labelAttributes;
+ (UIFont *)regularTextFont;
+ (UIFont *)regularTextFontSemiBold;
+ (NSDictionary *)regularTextAttributes;
+ (UIFont *)tableviewTextFont;
+ (UIFont *)tableviewSubtitleFont;
+ (UIFont *)tableviewSectionHeaderFont;
+ (UIFont *)tableviewSectionFooterFont;

// Color
+ (UIColor *)wordPressBlue;
+ (UIColor *)lightBlue;
+ (UIColor *)mediumBlue;
+ (UIColor *)darkBlue;
+ (UIColor *)grey;
+ (UIColor *)lightGrey;
+ (UIColor *)greyLighten30;
+ (UIColor *)greyLighten20;
+ (UIColor *)greyLighten10;
+ (UIColor *)greyDarken10;
+ (UIColor *)greyDarken20;
+ (UIColor *)greyDarken30;
+ (UIColor *)darkGrey;
+ (UIColor *)jazzyOrange;
+ (UIColor *)errorRed;

// Bar Button Styles
+ (UIBarButtonItemStyle)barButtonStyleForDone;
+ (UIBarButtonItemStyle)barButtonStyleForBordered;

+ (void)setRightBarButtonItemWithCorrectSpacing:(UIBarButtonItem *)barButtonItem forNavigationItem:(UINavigationItem *)navigationItem;

// Deprecated Colors
+ (UIColor *)newKidOnTheBlockBlue;
+ (UIColor *)midnightBlue;
@end

NS_ASSUME_NONNULL_END
