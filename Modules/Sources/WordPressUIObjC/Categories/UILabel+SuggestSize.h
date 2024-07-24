#import <UIKit/UIKit.h>

@interface UILabel (SuggestSize)

- (CGSize)suggestSizeForString:(NSString *)string width:(CGFloat)width;

@end
