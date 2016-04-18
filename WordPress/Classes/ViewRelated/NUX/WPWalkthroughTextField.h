#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface WPWalkthroughTextField : UITextField

@property (nonatomic) IBInspectable BOOL showTopLineSeparator;
@property (nonatomic) IBInspectable BOOL showSecureTextEntryToggle;
@property (nonatomic) IBInspectable UIImage *leftViewImage;
@property (nonatomic) UIEdgeInsets textInsets;
@property (nonatomic) UIOffset rightViewPadding;


- (instancetype)initWithLeftViewImage:(UIImage *)image;

@end
