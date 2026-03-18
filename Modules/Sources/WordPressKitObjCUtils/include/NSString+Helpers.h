#import <UIKit/UIKit.h>

@interface NSString (WPKitHelpers)

- (NSString *)wpkit_stringByUrlEncoding;
- (NSString *)wpkit_stringByStrippingHTML;
- (bool)wpkit_isEmpty;

@end

@interface NSString (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end

@interface NSObject (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end
