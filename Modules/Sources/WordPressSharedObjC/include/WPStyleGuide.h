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
+ (UIColor *)fireOrange;
+ (UIColor *)validGreen;
+ (UIColor *)warningYellow;
+ (UIColor *)errorRed;
+ (UIColor *)alertYellowDark;
+ (UIColor *)alertYellowLighter;
+ (UIColor *)alertRedDarker;

// Misc
+ (UIColor *)keyboardColor;
+ (UIColor *)textFieldPlaceholderGrey;

// Bar Button Styles
+ (UIBarButtonItemStyle)barButtonStyleForDone;
+ (UIBarButtonItemStyle)barButtonStyleForBordered;
+ (void)setLeftBarButtonItemWithCorrectSpacing:(UIBarButtonItem *)barButtonItem forNavigationItem:(UINavigationItem *)navigationItem;
+ (void)setRightBarButtonItemWithCorrectSpacing:(UIBarButtonItem *)barButtonItem forNavigationItem:(UINavigationItem *)navigationItem;
+ (void)configureNavigationBarAppearance;
+ (void)configureDocumentPickerNavBarAppearance;

// Move to a feature category
+ (UIColor *)buttonActionColor;
+ (UIColor *)nuxFormText;
+ (UIColor *)nuxFormPlaceholderText;

// Deprecated Colors
+ (UIColor *)baseLighterBlue;
+ (UIColor *)baseDarkerBlue;
+ (UIColor *)newKidOnTheBlockBlue;
+ (UIColor *)midnightBlue;
+ (UIColor *)bigEddieGrey;
+ (UIColor *)littleEddieGrey;
+ (UIColor *)whisperGrey;
+ (UIColor *)allTAllShadeGrey;
+ (UIColor *)readGrey;
+ (UIColor *)itsEverywhereGrey;
+ (UIColor *)darkAsNightGrey;
+ (UIColor *)validationErrorRed;

@end

NS_ASSUME_NONNULL_END
