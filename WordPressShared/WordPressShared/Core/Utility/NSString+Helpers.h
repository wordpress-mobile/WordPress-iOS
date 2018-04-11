#import <UIKit/UIKit.h>

@interface NSString (Helpers)

/**
 Transforms the specified string to plain text.  HTML markup is removed and HTML entities are decoded.

 @param string The string to transform.
 @return The transformed string.
 */
+ (NSString *)makePlainText:(NSString *)string;

/**
 Removes shortcodes from the passed string.

 @param string The string to remove shortcodes from.
 @return The modified string.
 */
+ (NSString *)stripShortcodesFromString:(NSString *)string;

/**
 Create a summary for the post based on the post's content.

 @param string The post's content string. This should be the formatted content string.
 @return A summary for the post.
 */
+ (NSString *)summaryFromContent:(NSString *)string;

- (NSString *)stringByUrlEncoding;
- (NSMutableDictionary *)dictionaryFromQueryString;
- (NSString *)stringByReplacingHTMLEmoticonsWithEmoji;
- (NSString *)stringByStrippingHTML;
- (NSString *)stringByEllipsizingWithMaxLength:(NSInteger)lengthlimit preserveWords:(BOOL)preserveWords;
- (BOOL)isWordPressComPath;

/**
 *  Counts the number of words in a string
 *  
 *  @discussion This word counting algorithm is from : http://stackoverflow.com/a/13367063
 *  @return the number of words in a string
 */
- (NSUInteger)wordCount;


- (NSString *)stringByNormalizingWhitespace;

@end
