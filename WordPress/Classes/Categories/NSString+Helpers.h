#import <UIKit/UIKit.h>

@interface NSString (Helpers)

/**
 Transforms the specified string to plain text.  HTML markup is removed and HTML entities are decoded.

 @param string The string to transform.
 @return The transformed string.
 */
+ (NSString *)makePlainText:(NSString *)string;

- (NSString *)stringByUrlEncoding;
- (NSString *)md5;
- (NSMutableDictionary *)dictionaryFromQueryString;
- (NSString *)stringByReplacingHTMLEmoticonsWithEmoji;
- (NSString *)stringByStrippingHTML;
- (NSString *)stringByEllipsizingWithMaxLength:(NSInteger)lengthlimit preserveWords:(BOOL)preserveWords;
- (NSString *)hostname;
- (BOOL)isWordPressComPath;

@end
