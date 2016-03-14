#import "WPNUXMainButton.h"
#import <WordPressShared/WPFontManager.h>

@implementation WPNUXMainButton {
    UIActivityIndicatorView *activityIndicator;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (void)layoutSubviews
{

    [super layoutSubviews];
    if ([activityIndicator isAnimating]) {

        // hide the title label when the activity indicator is visible
        self.titleLabel.frame = CGRectZero;
        activityIndicator.frame = CGRectMake((self.frame.size.width - activityIndicator.frame.size.width) / 2.0, (self.frame.size.height - activityIndicator.frame.size.height) / 2.0, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
    }
}

- (void)configureButton
{
    [self setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateDisabled];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateHighlighted];
    self.titleLabel.font = [WPFontManager systemRegularFontOfSize:18.0];
    [self setColor:[UIColor colorWithRed:0/255.0f green:116/255.0f blue:162/255.0f alpha:1.0f]];

    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.hidesWhenStopped = YES;
    [self addSubview:activityIndicator];
}

- (void)showActivityIndicator:(BOOL)show
{
    if (show) {
        [activityIndicator startAnimating];
    } else {
        [activityIndicator stopAnimating];
    }
    [self setNeedsLayout];
}

- (void)setColor:(UIColor *)color
{
    CGRect fillRect = CGRectMake(0, 0, 11.0, 40.0);
    UIEdgeInsets capInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    UIImage *mainImage;

    UIGraphicsBeginImageContextWithOptions(fillRect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:3.0].CGPath);
    CGContextClip(context);
    CGContextFillRect(context, fillRect);
    mainImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self setBackgroundImage:[mainImage resizableImageWithCapInsets:capInsets] forState:UIControlStateNormal];
}

@end
