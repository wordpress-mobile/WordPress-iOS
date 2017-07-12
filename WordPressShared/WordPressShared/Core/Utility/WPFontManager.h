#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface WPFontManager : NSObject

+ (UIFont *)systemLightFontOfSize:(CGFloat)size;
+ (UIFont *)systemItalicFontOfSize:(CGFloat)size;
+ (UIFont *)systemBoldFontOfSize:(CGFloat)size;
+ (UIFont *)systemSemiBoldFontOfSize:(CGFloat)size;
+ (UIFont *)systemRegularFontOfSize:(CGFloat)size;

/// Loads the Noto font family for the life of the current process.
/// This effectively makes it possible to look this font up using font descriptors.
///
+ (void)loadNotoFontFamily;
+ (UIFont *)notoBoldFontOfSize:(CGFloat)size;
+ (UIFont *)notoBoldItalicFontOfSize:(CGFloat)size;
+ (UIFont *)notoItalicFontOfSize:(CGFloat)size;
+ (UIFont *)notoRegularFontOfSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
