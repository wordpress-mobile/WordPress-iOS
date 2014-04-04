#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UITextField (UIKitTestHelper)
- (void)typeText:(NSString *)text;
@end

@interface UITextView (UIKitTestHelper)
- (void)typeText:(NSString *)text;
@end