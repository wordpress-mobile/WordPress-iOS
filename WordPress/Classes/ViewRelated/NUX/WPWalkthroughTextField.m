#import "WPWalkthroughTextField.h"
#import "Constants.h"
#import <WordPressShared/WPNUXUtility.h>
#import "WordPress-Swift.h"

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

        self.leftView = [[UIImageView alloc] initWithImage:leftViewImage];
        self.leftViewMode = UITextFieldViewModeAlways;
    } else {
        self.leftView = nil;
    }
}

- (void)commonInit
{
    self.textInsets = UIEdgeInsetsMake(7, 10, 7, 10);
    self.layer.cornerRadius = 0.0;
    self.clipsToBounds = YES;
    self.showTopLineSeparator = NO;
    self.showSecureTextEntryToggle = NO;

    self.secureTextEntryImageVisible = [Gridicon iconOfType:GridiconTypeVisible];
    self.secureTextEntryImageHidden = [Gridicon iconOfType:GridiconTypeNotVisible];

    self.secureTextEntryToggle = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secureTextEntryToggle.tintColor = [WPStyleGuide greyLighten10];
    self.secureTextEntryToggle.frame = CGRectMake(0, 0, 40, 30);
    [self.secureTextEntryToggle addTarget:self action:@selector(secureTextEntryToggleAction:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.secureTextEntryToggle];
    [self updateSecureTextEntryToggleImage];

    // Apply styles to the placeholder if one was set in IB.
    if (self.placeholder) {
        NSDictionary *attributes = @{
                                     NSForegroundColorAttributeName : WPStyleGuide.greyLighten10,
                                     NSFontAttributeName : self.font,
                                     };
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:attributes];
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(0.0, 44.0);
}

- (void)drawRect:(CGRect)rect
{
    // Draw top border
    if (_showTopLineSeparator) {

        CGContextRef context = UIGraphicsGetCurrentContext();

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(CGRectGetMinX(rect) + _textInsets.left, CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
        [path setLineWidth:[[UIScreen mainScreen] scale] / 2.0];
        CGContextAddPath(context, path.CGPath);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.87 alpha:1.0].CGColor);
        CGContextStrokePath(context);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.secureTextEntryToggle.hidden = !self.showSecureTextEntryToggle;
    if (self.showSecureTextEntryToggle) {
        CGRect frame = self.secureTextEntryToggle.frame;
        if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight) {
            frame = CGRectIntegral(CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.secureTextEntryToggle.frame),
                                              (CGRectGetHeight(self.bounds) - CGRectGetHeight(self.secureTextEntryToggle.frame)) / 2.0,
                                              CGRectGetWidth(self.secureTextEntryToggle.frame),
                                              CGRectGetHeight(self.secureTextEntryToggle.frame)));
        } else {
            frame = CGRectIntegral(CGRectMake(CGRectGetMinX(self.bounds),
                                              (CGRectGetHeight(self.bounds) - CGRectGetHeight(self.secureTextEntryToggle.frame)) / 2.0,
                                              CGRectGetWidth(self.secureTextEntryToggle.frame),
                                              CGRectGetHeight(self.secureTextEntryToggle.frame)));
        }
        self.secureTextEntryToggle.frame = frame;
        [self bringSubviewToFront:self.secureTextEntryToggle];
    }
}

- (CGRect)calculateTextRectForBounds:(CGRect)bounds
{
    CGRect returnRect;
    
    if (_leftViewImage) {
        CGFloat leftViewWidth = _leftViewImage.size.width;
        returnRect = CGRectMake(leftViewWidth + 2 * _textInsets.left, _textInsets.top, bounds.size.width - leftViewWidth - 2 * _textInsets.left - _textInsets.right, bounds.size.height - _textInsets.top - _textInsets.bottom);
    } else {
        returnRect = CGRectMake(_textInsets.left, _textInsets.top, bounds.size.width - _textInsets.left - _textInsets.right, bounds.size.height - _textInsets.top - _textInsets.bottom);
    }

    if (self.showSecureTextEntryToggle) {
        returnRect.size.width -= CGRectGetWidth(self.secureTextEntryToggle.frame);
    }
    
    if (self.rightView && self.rightViewMode != UITextFieldViewModeNever) {
        returnRect.size.width -= CGRectGetWidth(self.rightView.frame);
    }

    return CGRectIntegral(returnRect);
}

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [self calculateTextRectForBounds:bounds];
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self calculateTextRectForBounds:bounds];
}

// left view position
- (CGRect)leftViewRectForBounds:(CGRect)bounds
{

    if (_leftViewImage) {
        return CGRectIntegral(CGRectMake(_textInsets.left, (CGRectGetHeight(bounds) - _leftViewImage.size.height) / 2.0, _leftViewImage.size.width, _leftViewImage.size.height));
    }

    return [super leftViewRectForBounds:bounds];
}

// Right view position
- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGRect textRect = [super rightViewRectForBounds:bounds];
    textRect.origin.x -= _rightViewPadding.horizontal;
    textRect.origin.y -= _rightViewPadding.vertical;
    
    return textRect;
}


#pragma mark - Secure Text Entry

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
    // This is a fix for a bug where the text field reverts to a system
    // serif font if you disable secure text entry while it contains text.
    self.font = nil;
    self.font = [WPNUXUtility textFieldFont];

    [super setSecureTextEntry:secureTextEntry];
    [self updateSecureTextEntryToggleImage];
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
}

@end
