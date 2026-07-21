#import <Foundation/Foundation.h>

@interface NSString (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end

@interface NSObject (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end
