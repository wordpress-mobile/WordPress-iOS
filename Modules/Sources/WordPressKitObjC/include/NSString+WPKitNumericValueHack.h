#import <UIKit/UIKit.h>

@interface NSString (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end

@interface NSObject (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end
