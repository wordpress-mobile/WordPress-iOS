#import <UIKit/UIKit.h>

@interface MenusActionButton : UIButton

@property (nonatomic, copy) UIColor *backgroundBaseColor;
@property (nonatomic, copy) UIColor *backgroundFillColor;

- (UIImage *)templatedIconImageNamed:(NSString *)imageName;

@end
