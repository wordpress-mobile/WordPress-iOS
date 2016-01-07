#import <UIKit/UIKit.h>

@interface MenusActionButton : UIButton

@property (nonatomic, copy) UIColor *baseColor;
@property (nonatomic, copy) UIColor *fillColor;

- (UIImage *)templatedIconImageNamed:(NSString *)imageName;

@end
