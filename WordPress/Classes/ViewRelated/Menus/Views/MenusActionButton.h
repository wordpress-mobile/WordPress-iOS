#import <UIKit/UIKit.h>

@interface MenusActionButton : UIButton

@property (nonatomic, copy) UIColor *backgroundDrawColor;

- (UIImage *)templatedIconImageNamed:(NSString *)imageName;

@end
