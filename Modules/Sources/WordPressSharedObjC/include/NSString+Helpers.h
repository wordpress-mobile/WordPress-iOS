#import <UIKit/UIKit.h>

@interface NSString (Helpers)

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
