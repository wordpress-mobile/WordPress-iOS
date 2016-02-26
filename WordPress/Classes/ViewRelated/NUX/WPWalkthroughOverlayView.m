#import "WPWalkthroughOverlayView.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPNUXUtility.h"
#import "UILabel+SuggestSize.h"
#import <WordPressShared/WPFontManager.h>

@interface WPWalkthroughOverlayView() {
    UIImageView *_logo;
    UILabel *_title;
    UILabel *_description;
    UILabel *_bottomLabel;
    WPNUXSecondaryButton *_secondaryButton;
    WPNUXPrimaryButton *_primaryButton;

    CGFloat _viewWidth;
    CGFloat _viewHeight;

    UITapGestureRecognizer *_gestureRecognizer;
}

@end

@implementation WPWalkthroughOverlayView

CGFloat const WPWalkthroughGrayOverlayIconVerticalOffset = 75.0;
CGFloat const WPWalkthroughGrayOverlayStandardOffset = 16.0;
CGFloat const WPWalkthroughGrayOverlayBottomLabelOffset = 91.0;
CGFloat const WPWalkthroughGrayOverlayBottomPanelHeight = 64.0;
CGFloat const WPWalkthroughGrayOverlayMaxLabelWidth = 289.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _overlayMode = WPWalkthroughGrayOverlayViewOverlayModePrimaryButton;
        [self configureBackgroundColor];
        [self addViewElements];
        [self addGestureRecognizer];
        [self setPrimaryButtonText:NSLocalizedString(@"OK", nil)];
    }
    return self;
}

- (void)setOverlayMode:(WPWalkthroughOverlayViewOverlayMode)overlayMode
{
    if (_overlayMode != overlayMode) {
        _overlayMode = overlayMode;
        [self adjustOverlayDismissal];
        [self setNeedsLayout];
    }
}

- (void)setOverlayTitle:(NSString *)overlayTitle
{
    if (_overlayTitle != overlayTitle) {
        _overlayTitle = overlayTitle;
        _title.text = _overlayTitle;
        [self setNeedsLayout];
    }
}

- (void)setOverlayDescription:(NSString *)overlayDescription
{
    if (_overlayDescription != overlayDescription) {
        _overlayDescription = overlayDescription;
        _description.text = _overlayDescription;
        [self setNeedsLayout];
    }
}

- (void)setFooterDescription:(NSString *)footerDescription
{
    if (_footerDescription != footerDescription) {
        _footerDescription = footerDescription;
        _bottomLabel.text = _footerDescription;
        [self setNeedsLayout];
    }
}

- (void)setSecondaryButtonText:(NSString *)leftButtonText
{
    if (_secondaryButtonText != leftButtonText) {
        _secondaryButtonText = leftButtonText;
        [_secondaryButton setTitle:_secondaryButtonText forState:UIControlStateNormal];
        [_secondaryButton sizeToFit];
        [self setNeedsLayout];
    }
}

- (void)setPrimaryButtonText:(NSString *)rightButtonText
{
    if (_primaryButtonText != rightButtonText) {
        _primaryButtonText = rightButtonText;
        [_primaryButton setTitle:_primaryButtonText forState:UIControlStateNormal];
        [_primaryButton sizeToFit];
        [self setNeedsLayout];
    }
}

- (void)setIcon:(WPWalkthroughOverlayViewIcon)icon
{
    if (_icon != icon) {
        _icon = icon;
        [self configureIcon];
        [self setNeedsLayout];
    }
}

- (void)setHideBackgroundView:(BOOL)hideBackgroundView
{
    if (_hideBackgroundView != hideBackgroundView) {
        _hideBackgroundView = hideBackgroundView;
        [self configureBackgroundColor];
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _viewWidth = CGRectGetWidth(self.bounds);
    _viewHeight = CGRectGetHeight(self.bounds);

    CGFloat x, y;

    // Layout Logo
    [self configureIcon];
    x = (_viewWidth - CGRectGetWidth(_logo.frame))/2.0;
    y = WPWalkthroughGrayOverlayIconVerticalOffset;
    _logo.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_logo.frame), CGRectGetHeight(_logo.frame)));

    // Layout Title
    CGSize titleSize = [_title suggestedSizeForWidth:WPWalkthroughGrayOverlayMaxLabelWidth];
    x = (_viewWidth - titleSize.width)/2.0;
    y = CGRectGetMaxY(_logo.frame) + 0.5*WPWalkthroughGrayOverlayStandardOffset;
    _title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));

    // Layout Description
    CGSize labelSize = [_description suggestedSizeForWidth:WPWalkthroughGrayOverlayMaxLabelWidth];
    x = (_viewWidth - labelSize.width)/2.0;
    y = CGRectGetMaxY(_title.frame) + 0.5*WPWalkthroughGrayOverlayStandardOffset;
    _description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));

    // Layout Bottom Label
    CGSize bottomLabelSize = [_bottomLabel.text sizeWithAttributes:@{NSFontAttributeName:_bottomLabel.font}];
    x = (_viewWidth - bottomLabelSize.width)/2.0;
    y = _viewHeight - WPWalkthroughGrayOverlayBottomLabelOffset;
    _bottomLabel.frame = CGRectIntegral(CGRectMake(x, y, bottomLabelSize.width, bottomLabelSize.height));

    // Layout Bottom Buttons
    if (self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModePrimaryButton ||
        self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode) {

        x = _viewWidth - CGRectGetWidth(_primaryButton.frame) - WPWalkthroughGrayOverlayStandardOffset;
        y = (_viewHeight - WPWalkthroughGrayOverlayBottomPanelHeight + WPWalkthroughGrayOverlayStandardOffset);
        _primaryButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_primaryButton.frame), CGRectGetHeight(_primaryButton.frame)));
    } else {
        _primaryButton.frame = CGRectZero;
    }

    if (self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode) {

        x = WPWalkthroughGrayOverlayStandardOffset;
        y = (_viewHeight - WPWalkthroughGrayOverlayBottomPanelHeight + WPWalkthroughGrayOverlayStandardOffset);
        _secondaryButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_secondaryButton.frame), CGRectGetHeight(_secondaryButton.frame)));
    } else {
        _secondaryButton.frame = CGRectZero;
    }

    CGFloat heightFromBottomLabel = _viewHeight - CGRectGetMinY(_bottomLabel.frame) - CGRectGetHeight(_bottomLabel.frame);
    NSArray *viewsToCenter = @[_logo, _title, _description];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_logo andEndingView:_description forHeight:(_viewHeight-heightFromBottomLabel)];
}

- (void)dismiss
{
    [self removeFromSuperview];
}

#pragma mark - Private Methods

- (void)configureBackgroundColor
{
    CGFloat alpha = 0.95;
    if (self.hideBackgroundView) {
        alpha = 1.0;
    }
    self.backgroundColor = [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:alpha];
}

- (void)addGestureRecognizer
{
    _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnView:)];
    _gestureRecognizer.numberOfTapsRequired = 1;
    _gestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_gestureRecognizer];
}

- (void)addViewElements
{
    // Add Icon
    _logo = [[UIImageView alloc] init];
    [self configureIcon];
    [self addSubview:_logo];

    // Add Title
    _title = [[UILabel alloc] init];
    _title.backgroundColor = [UIColor clearColor];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.numberOfLines = 0;
    _title.lineBreakMode = NSLineBreakByWordWrapping;
    _title.font = [WPFontManager systemLightFontOfSize:25.0];
    _title.text = self.overlayTitle;
    _title.shadowColor = [UIColor blackColor];
    _title.shadowOffset = CGSizeMake(1.0, 1.0);
    _title.textColor = [UIColor whiteColor];
    [self addSubview:_title];

    // Add Description
    _description = [[UILabel alloc] init];
    _description.backgroundColor = [UIColor clearColor];
    _description.textAlignment = NSTextAlignmentCenter;
    _description.numberOfLines = 0;
    _description.lineBreakMode = NSLineBreakByWordWrapping;
    _description.font = [WPNUXUtility descriptionTextFont];
    _description.text = self.overlayDescription;
    _description.shadowColor = [UIColor blackColor];
    _description.textColor = [UIColor whiteColor];
    [self addSubview:_description];

    // Add Bottom Label
    _bottomLabel = [[UILabel alloc] init];
    _bottomLabel.backgroundColor = [UIColor clearColor];
    _bottomLabel.textAlignment = NSTextAlignmentCenter;
    _bottomLabel.numberOfLines = 1;
    _bottomLabel.font = [WPFontManager systemRegularFontOfSize:10.0];
    _bottomLabel.text = self.footerDescription;
    _bottomLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
    [self addSubview:_bottomLabel];

    // Add Button 1
    _secondaryButton = [[WPNUXSecondaryButton alloc] init];
    [_secondaryButton setTitle:self.secondaryButtonText forState:UIControlStateNormal];
    [_secondaryButton sizeToFit];
    [_secondaryButton addTarget:self action:@selector(secondaryButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_secondaryButton];

    // Add Button 2
    _primaryButton = [[WPNUXPrimaryButton alloc] init];
    [_primaryButton setTitle:self.primaryButtonText forState:UIControlStateNormal];
    [_primaryButton sizeToFit];
    [_primaryButton addTarget:self action:@selector(primaryButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_primaryButton];
}

- (void)configureIcon
{
    UIImage *image;
    if (self.icon == WPWalkthroughGrayOverlayViewWarningIcon) {
        image = [UIImage imageNamed:@"icon-alert"];
    } else {
        image = [UIImage imageNamed:@"icon-check-blue"];
    }
    [_logo setImage:image];
    [_logo sizeToFit];
}

- (void)adjustOverlayDismissal
{
    // We always want a tap on the view to dismiss
    _gestureRecognizer.numberOfTapsRequired = 1;
}

- (void)tappedOnView:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self];

    // To avoid accidentally dismissing the view when the user was trying to tap one of the buttons,
    // add some padding around the button frames.
    CGRect button1Frame = CGRectInset(_secondaryButton.frame, -2 * WPWalkthroughGrayOverlayStandardOffset, -WPWalkthroughGrayOverlayStandardOffset);
    CGRect button2Frame = CGRectInset(_primaryButton.frame, -2 * WPWalkthroughGrayOverlayStandardOffset, -WPWalkthroughGrayOverlayStandardOffset);

    BOOL touchedButton1 = CGRectContainsPoint(button1Frame, touchPoint);
    BOOL touchedButton2 = CGRectContainsPoint(button2Frame, touchPoint);

    if (touchedButton1 || touchedButton2) {
        return;
    }

    if (gestureRecognizer.numberOfTapsRequired == 1) {
        if (self.dismissCompletionBlock) {
            self.dismissCompletionBlock(self);
        }
    }
}

- (void)secondaryButtonAction
{
    if (self.secondaryButtonCompletionBlock) {
        self.secondaryButtonCompletionBlock(self);
    } else if (self.dismissCompletionBlock) {
        self.dismissCompletionBlock(self);
    }
}

- (void)primaryButtonAction
{
    if (self.primaryButtonCompletionBlock) {
        self.primaryButtonCompletionBlock(self);
    } else if (self.dismissCompletionBlock) {
        self.dismissCompletionBlock(self);
    }
}

@end
