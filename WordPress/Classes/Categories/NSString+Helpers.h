#import <UIKit/UIKit.h>

@interface NSString (Helpers)

- (NSString *)stringByUrlEncoding;
- (NSString *)md5;
- (NSMutableDictionary *)dictionaryFromQueryString;
- (NSString *)stringByReplacingHTMLEmoticonsWithEmoji;
- (NSString *)stringByStrippingHTML;
- (NSString *)stringByEllipsizingWithMaxLength:(NSInteger)lengthlimit preserveWords:(BOOL)preserveWords;
- (NSString *)hostname;
- (BOOL)isWordPressComPath;

@end
