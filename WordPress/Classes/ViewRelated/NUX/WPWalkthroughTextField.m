#import "WPWalkthroughTextField.h"

@interface WPWalkthroughTextField ()
@property (nonatomic, strong) UIButton *secureTextEntryToggle;
@property (nonatomic, strong) UIImage *secureTextEntryImageVisible;
@property (nonatomic, strong) UIImage *secureTextEntryImageHidden;
@property (nonatomic, assign) BOOL viewIsConfigured;
@end

@implementation WPWalkthroughTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
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

- (void)configureView
{
    self.textInsets = UIEdgeInsetsMake(7, 10, 7, 10);
    self.layer.cornerRadius = 1.0;
    self.clipsToBounds = YES;

    /*
     We need to specify the bundle so Interface Builder can load the resources
     
     `-[UIImage imageNamed:` defaults to the main bundle, which in IB won't match
     the app's bundle.
     
     See https://stackoverflow.com/questions/24603232/xcode-6-ib-designable-not-loading-resources-from-bundle-in-interface-builder
     */
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        self.secureTextEntryImageVisible = [UIImage imageNamed:@"icon-secure-text-visible" inBundle:bundle compatibleWithTraitCollection:self.traitCollection];
        self.secureTextEntryImageHidden = [UIImage imageNamed:@"icon-secure-text" inBundle:bundle compatibleWithTraitCollection:self.traitCollection];
    } else {
        self.secureTextEntryImageVisible = [UIImage imageNamed:@"icon-secure-text-visible"];
        self.secureTextEntryImageHidden = [UIImage imageNamed:@"icon-secure-text"];
    }

    self.secureTextEntryToggle = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secureTextEntryToggle.frame = CGRectMake(0, 0, 40, 30);
    [self.secureTextEntryToggle addTarget:self action:@selector(secureTextEntryToggleAction:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.secureTextEntryToggle];
    [self updateSecureTextEntryToggleImage];
    [self configureLeftView];
    self.viewIsConfigured = YES;
}

- (void)configureLeftView
{
    if (self.leftViewImage) {
        self.leftView = [[UIImageView alloc] initWithImage:self.leftViewImage];
        self.leftViewMode = UITextFieldViewModeAlways;
    } else {
        self.leftView = nil;
        self.leftViewMode = UITextFieldViewModeNever;
    }
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

    if (!self.viewIsConfigured) {
        [self configureView];
    }
    [super layoutSubviews];

    self.secureTextEntryToggle.hidden = !self.showSecureTextEntryToggle;
    if (self.showSecureTextEntryToggle) {
        self.secureTextEntryToggle.frame = CGRectIntegral(CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.secureTextEntryToggle.frame),
                                                                     (CGRectGetHeight(self.bounds) - CGRectGetHeight(self.secureTextEntryToggle.frame)) / 2.0,
                                                                     CGRectGetWidth(self.secureTextEntryToggle.frame),
                                                                     CGRectGetHeight(self.secureTextEntryToggle.frame)));
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
    textRect.origin.x -= _rightViewPadding.x;
    textRect.origin.y -= _rightViewPadding.y;
    
    return textRect;
}


#pragma mark - Secure Text Entry

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
    [super setSecureTextEntry:secureTextEntry];
    [self updateSecureTextEntryToggleImage];
}

- (void)secureTextEntryToggleAction:(id)sender
{
    [self setSecureTextEntry:!self.isSecureTextEntry];
    self.text = self.text; // Fixes cursor position after toggling
    [self setNeedsDisplay];
}

- (void)updateSecureTextEntryToggleImage
{
    UIImage *image = self.isSecureTextEntry ? self.secureTextEntryImageHidden : self.secureTextEntryImageVisible;
    [self.secureTextEntryToggle setImage:image forState:UIControlStateNormal];
}

@end
