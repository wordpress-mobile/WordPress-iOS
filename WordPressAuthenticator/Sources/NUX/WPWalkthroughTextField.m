#import "WPWalkthroughTextField.h"

@import WordPressShared;

NSInteger const LeftImageSpacing = 8;

@import Gridicons;

@interface WPWalkthroughTextField ()
@property (nonatomic, strong) UIButton *secureTextEntryToggle;
@property (nonatomic, strong) UIImage *secureTextEntryImageVisible;
@property (nonatomic, strong) UIImage *secureTextEntryImageHidden;
@end

@implementation WPWalkthroughTextField

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithLeftViewImage:(UIImage *)image
{
    self = [self init];
    if (self) {
        self.leftViewImage = image;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)setLeftViewImage:(UIImage *)leftViewImage
{
    if (leftViewImage) {
        _leftViewImage = leftViewImage;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:leftViewImage];
        if (self.leadingViewWidth > 0) {
            imageView.frame = [self frameForLeadingView];
            imageView.contentMode = [self isLayoutLeftToRight] ? UIViewContentModeLeft : UIViewContentModeRight;
        } else {
            [imageView sizeToFit];
        }
        self.leftView = imageView;
        self.leftViewMode = UITextFieldViewModeAlways;
    } else {
        self.leftView = nil;
    }
}

-(void)setRightView:(UIView *)rightView
{
    if (self.trailingViewWidth > 0) {
        rightView.frame = [self frameForTrailingView];
        rightView.contentMode = [self isLayoutLeftToRight] ? UIViewContentModeRight : UIViewContentModeLeft;
        if ([rightView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)rightView;
            if ([self isLayoutLeftToRight]) {
                [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            } else {
                [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            }
        }
    }
    [super setRightView:rightView];
}

- (void)setShowSecureTextEntryToggle:(BOOL)showSecureTextEntryToggle
{
    _showSecureTextEntryToggle = showSecureTextEntryToggle;
    [self configureSecureTextEntryToggle];
}

- (void)commonInit
{
    self.leadingViewWidth = 30.f;
    self.trailingViewWidth = 40.f;

    self.layer.cornerRadius = 0.0;
    self.clipsToBounds = YES;
    self.showTopLineSeparator = NO;
    self.showSecureTextEntryToggle = NO;

    // Apply styles to the placeholder if one was set in IB.
    if (self.placeholder) {
        // colors here are overridden in LoginTextField
        NSDictionary *attributes = @{
                                     NSForegroundColorAttributeName : WPStyleGuide.greyLighten10,
                                     NSFontAttributeName : self.font,
                                     };
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:attributes];
    }

    self.leadingViewInsets = UIEdgeInsetsMake(0, 0, 0, LeftImageSpacing);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureSecureTextEntryToggle];
}

- (void)configureSecureTextEntryToggle {
    if (self.showSecureTextEntryToggle == NO) {
        return;
    }
    self.secureTextEntryImageVisible = [UIImage gridiconOfType:GridiconTypeVisible];
    self.secureTextEntryImageHidden = [UIImage gridiconOfType:GridiconTypeNotVisible];

    self.secureTextEntryToggle = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secureTextEntryToggle.clipsToBounds = true;

    // Tint color changes set in LoginTextField.

    [self.secureTextEntryToggle addTarget:self action:@selector(secureTextEntryToggleAction:) forControlEvents:UIControlEventTouchUpInside];

    [self updateSecureTextEntryToggleImage];
    [self updateSecureTextEntryForAccessibility];

    self.rightView = self.secureTextEntryToggle;
    self.rightViewMode = UITextFieldViewModeAlways;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(0.0, 44.0);
}

- (void)drawRect:(CGRect)rect
{
    // Draw top border
    if (!self.showTopLineSeparator) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat emptySpace = self.contentInsets.left;
    if ([self isLayoutLeftToRight]) {
        [path moveToPoint:CGPointMake(CGRectGetMinX(rect) + emptySpace, CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
    } else {
        [path moveToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - emptySpace, CGRectGetMinY(rect))];
    }

    [path setLineWidth:[[UIScreen mainScreen] scale] / 2.0];
    CGContextAddPath(context, path.CGPath);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.87 alpha:1.0].CGColor);
    CGContextStrokePath(context);
}


/// Returns the drawing rectangle for the text field’s text.
///
- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect rect = [super textRectForBounds:bounds];
    return [self textAreaRectForProposedRect:rect];
}

/// Returns the rectangle in which editable text can be displayed.
///
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];
    return [self textAreaRectForProposedRect:rect];
}

/// Returns the drawing rectangle of the receiver’s left overlay view.
/// This value is always the view seen at the left side, independently of the layout direction.
///
- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    CGRect rect = [super leftViewRectForBounds:bounds];
    if ([self isLayoutLeftToRight]) {
        rect.origin.x += self.leadingViewInsets.left + self.contentInsets.left;
    } else {
        rect.origin.x += self.trailingViewInsets.right + self.contentInsets.right;
    }
    return rect;
}

/// Returns the drawing location of the receiver’s right overlay view.
/// This value is always the view seen at the right side, independently of the layout direction.
///
- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGRect rect = [super rightViewRectForBounds:bounds];
    if ([self isLayoutLeftToRight]) {
        rect.origin.x -= self.trailingViewInsets.right + self.contentInsets.right;
    } else {
        rect.origin.x -= self.leadingViewInsets.left + self.contentInsets.left;
    }
    return rect;
}

#pragma mark - Helpers

- (BOOL)isLayoutLeftToRight
{
    return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionLeftToRight;
}

/// Returns the rectangle in which both editable text and the placeholder can be displayed.
///
- (CGRect)textAreaRectForProposedRect:(CGRect)rect
{
    rect.size.width -= self.textInsets.left + self.textInsets.right;
    if ([self isLayoutLeftToRight]) {
        rect.origin.x   += self.textInsets.left + self.leadingViewInsets.right;
        rect.size.width -= self.leadingViewInsets.right + self.contentInsets.right;
        if (self.leftView == nil) {
            rect.origin.x   += self.contentInsets.left;
            rect.size.width -= self.contentInsets.right;
        }
    } else {
        rect.origin.x   += self.textInsets.right + self.trailingViewInsets.left;
        rect.size.width -= self.leadingViewInsets.right + self.trailingViewInsets.left;
        if (self.rightView == nil) {
            rect.origin.x   += self.contentInsets.right;
            rect.size.width -= self.contentInsets.left;
        }
        if (self.leftView == nil) {
            rect.size.width -= self.contentInsets.left;
        }
    }
    return rect;
}

- (CGRect)frameForTrailingView
{
    return CGRectMake(0, 0, self.trailingViewWidth, CGRectGetHeight(self.bounds));
}

- (CGRect)frameForLeadingView
{
    return CGRectMake(0, 0, self.leadingViewWidth, CGRectGetHeight(self.bounds));
}

#pragma mark - Secure Text Entry

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
    // This is a fix for a bug where the text field reverts to a system
    // serif font if you disable secure text entry while it contains text.
    self.font = nil;
    self.font = [WPFontManager systemRegularFontOfSize:16.0];

    [super setSecureTextEntry:secureTextEntry];
    [self updateSecureTextEntryToggleImage];
    [self updateSecureTextEntryForAccessibility];
}

- (void)secureTextEntryToggleAction:(id)sender
{
    self.secureTextEntry = !self.secureTextEntry;

    // Save and re-apply the current selection range to save the cursor position
    UITextRange *currentTextRange = self.selectedTextRange;
    [self becomeFirstResponder];
    [self setSelectedTextRange:currentTextRange];
}

- (void)updateSecureTextEntryToggleImage
{
    UIImage *image = self.isSecureTextEntry ? self.secureTextEntryImageHidden : self.secureTextEntryImageVisible;
    [self.secureTextEntryToggle setImage:image forState:UIControlStateNormal];
    [self.secureTextEntryToggle sizeToFit];
    self.secureTextEntryToggle.tintColor = self.secureTextEntryImageColor;
}

- (void)updateSecureTextEntryForAccessibility
{
    self.secureTextEntryToggle.accessibilityLabel = NSLocalizedString(@"Show password", @"Accessibility label for the “Show password“ button in the login page's password field.");

    NSString *accessibilityValue;
    if (self.isSecureTextEntry) {
        accessibilityValue = NSLocalizedString(@"Hidden", "Accessibility value if login page's password field is hiding the password (i.e. with asterisks).");
    } else {
        accessibilityValue = NSLocalizedString(@"Shown", "Accessibility value if login page's password field is displaying the password.");
    }
    self.secureTextEntryToggle.accessibilityValue = accessibilityValue;
}

@end
