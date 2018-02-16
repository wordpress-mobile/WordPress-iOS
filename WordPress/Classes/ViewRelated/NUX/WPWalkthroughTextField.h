#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface WPWalkthroughTextField : UITextField

@property (nonatomic) IBInspectable BOOL showTopLineSeparator;
@property (nonatomic) IBInspectable BOOL showSecureTextEntryToggle;
@property (nonatomic) IBInspectable UIImage *leftViewImage;

/// Width for the left view. Set to 0 to use the given frame in the view.
/// Default is: 30
///
@property (nonatomic) CGFloat leadingViewWidth;

/// Width for the right view. Set to 0 to use the given frame in the view.
/// Default is: 40
///
@property (nonatomic) CGFloat trailingViewWidth;

/// Insets around the text area.
/// This value is mirrored in Right-to-Left layout
///
@property (nonatomic) UIEdgeInsets textInsets;

/// Insets around the leading (left) view.
/// This value is mirrored in Right-to-Left layout
///
@property (nonatomic) UIEdgeInsets leadingViewInsets;

/// Insets around the trailing (right) view.
/// This value is mirrored in Right-to-Left layout
///
@property (nonatomic) UIEdgeInsets trailingViewInsets;

/// Insets around the whole content of the textfield.
/// This value is mirrored in Right-to-Left layout
///
@property (nonatomic) UIEdgeInsets contentInsets;

- (instancetype)initWithLeftViewImage:(UIImage *)image;

@end
