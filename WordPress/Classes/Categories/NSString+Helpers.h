#import <UIKit/UIKit.h>

@interface NSString (Helpers)

// helper functions
- (NSString *) stringByUrlEncoding;
- (NSString *) md5;
- (NSMutableDictionary *)dictionaryFromQueryString;
- (NSString *)stringByReplacingHTMLEmoticonsWithEmoji;
- (NSString *)stringByStrippingHTML;
- (NSString *)stringByRemovingScripts;
- (NSString *)stringByEllipsizingWithMaxLength:(NSInteger)lengthlimit preserveWords:(BOOL)preserveWords;
@end
