#import <UIKit/UIKit.h>

@interface UIColor (Helpers)

// [UIColor UIColorFromHex:0xc5c5c5 alpha:0.8];
+ (UIColor *)UIColorFromHex:(NSUInteger)rgb alpha:(CGFloat)alpha;
+ (UIColor *)UIColorFromHex:(NSUInteger)rgb;

+ (UIColor *)colorWithHexString:(NSString *)hex;

- (NSString *)hexString;
@end
