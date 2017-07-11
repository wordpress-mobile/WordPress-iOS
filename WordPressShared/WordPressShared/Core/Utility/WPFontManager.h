#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface WPFontManager : NSObject

/// Uses the system fonts of the specified size.
/// As Apple says, "Think carefully before using these methods" as they do not respect the user's selected content size category.

/**
 Returns the system light font of the specified size.
 
 @param size CGFloat specifying the size of font to return

 @warning Font will not respect the user's selected content size category. Try WPStyleGuide.fontForTextStyle instead
 */
+ (UIFont *)systemLightFontOfSize:(CGFloat)size;

/**
 Returns the system italic font of the specified size.

 @param size CGFloat specifying the size of font to return

 @warning Font will not respect the user's selected content size category. Try WPStyleGuide.fontForTextStyle instead
 */
+ (UIFont *)systemItalicFontOfSize:(CGFloat)size;

/**
 Returns the system bold font of the specified size.

 @param size CGFloat specifying the size of font to return

 @warning Font will not respect the user's selected content size category. Try WPStyleGuide.fontForTextStyle instead
 */
+ (UIFont *)systemBoldFontOfSize:(CGFloat)size;

/**
 Returns the system semibold font of the specified size.

 @param size CGFloat specifying the size of font to return

 @warning Font will not respect the user's selected content size category. Try WPStyleGuide.fontForTextStyle instead
 */
+ (UIFont *)systemSemiBoldFontOfSize:(CGFloat)size;

/**
 Returns the system regular font of the specified size.

 @param size CGFloat specifying the size of font to return

 @warning Font will not respect the user's selected content size category. Try WPStyleGuide.fontForTextStyle instead
 */
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
