#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface WPWalkthroughTextField : UITextField

@property (nonatomic) UIEdgeInsets textInsets;
@property (nonatomic) CGPoint rightViewPadding;
@property (nonatomic) IBInspectable BOOL showTopLineSeparator;
@property (nonatomic) IBInspectable BOOL showSecureTextEntryToggle;
@property (nonatomic, strong) IBInspectable UIImage *leftViewImage;

- (instancetype)initWithLeftViewImage:(UIImage *)image;

@end
