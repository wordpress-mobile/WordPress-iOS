#import <UIKit/UIKit.h>

@interface WPKeyboardToolbarButtonItem : UIButton

@property (nonatomic, strong) NSString *actionTag, *actionName;

+ (id)button;
- (void)setImageName:(NSString *)imageName;
- (void)setImageName:(NSString *)imageName withColor:(UIColor *)tintColor highlightColor:(UIColor *)highlightColor;

@end
