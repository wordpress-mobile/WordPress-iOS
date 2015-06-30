#import <Foundation/Foundation.h>



@interface NSMutableAttributedString (Util)

- (void)applyAttributesToQuotes:(NSDictionary *)attributes;
- (void)applyFont:(UIFont *)font;
- (void)applyForegroundColor:(UIColor *)color;
- (void)applyUnderline;

@end
