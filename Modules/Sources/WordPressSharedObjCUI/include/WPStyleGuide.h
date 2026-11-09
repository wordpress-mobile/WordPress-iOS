#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WPTextFieldTableViewCell;

@interface WPStyleGuide : NSObject

// Fonts
+ (UIFont *)subtitleFont;
+ (NSDictionary *)subtitleAttributes;
+ (UIFont *)subtitleFontBold;
+ (NSDictionary *)subtitleAttributesBold;
+ (UIFont *)labelFont;
+ (UIFont *)labelFontNormal;
+ (UIFont *)regularTextFont;
+ (UIFont *)tableviewTextFont;

// Color
+ (UIColor *)wordPressBlue;
+ (UIColor *)mediumBlue;
+ (UIColor *)grey;
+ (UIColor *)darkGrey;

@end

NS_ASSUME_NONNULL_END
