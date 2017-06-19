#import <UIKit/UIKit.h>


@interface NSString (Util)

- (bool)isEmpty;
- (NSString *)trim;
- (NSNumber *)numericValue;
- (CGSize)suggestedSizeWithFont:(UIFont *)font width:(CGFloat)width;

@end

@interface NSObject (NumericValueHack)
- (NSNumber *)numericValue;
@end