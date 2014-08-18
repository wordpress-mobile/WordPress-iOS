#import "WPAlertView.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPNUXUtility.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

@interface WPAlertView() {
    UITapGestureRecognizer *_gestureRecognizer;
}

@property (nonatomic, assign) WPAlertViewOverlayMode overlayMode;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UIImageView *bottomSeparator;
@property (nonatomic, weak) IBOutlet UILabel *bottomLabel;
@property (nonatomic, weak) IBOutlet WPNUXSecondaryButton *leftButton;
@property (nonatomic, weak) IBOutlet WPNUXPrimaryButton *rightButton;
@property (nonatomic, strong) NSLayoutConstraint *originalFirstTextFieldConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *firstTextFieldLabelWidthConstraint;

@end

@implementation WPAlertView

CGFloat const WPAlertViewStandardOffset = 16.0;
CGFloat const WPAlertViewDefaultTextFieldLabelWidth = 118.0f;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame andOverlayMode:WPAlertViewOverlayModeTwoTextFieldsTwoButtonMode];

    return self;
}

- (id)initWithFrame:(CGRect)frame andOverlayMode:(WPAlertViewOverlayMode)overlayMode
{
    self = [super initWithFrame:frame];
    if (self) {
        _overlayMode = overlayMode;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:frame];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _scrollView = scrollView;
        [self addSubview:scrollView];

        UIView *backgroundView = nil;

        if (_overlayMode == WPAlertViewOverlayModeTwoTextFieldsSideBySideTwoButtonMode) {
            backgroundView = [[NSBundle mainBundle] loadNibNamed:@"WPAlertViewSideBySide" owner:self options:nil][0];
        } else {
            backgroundView = [[NSBundle mainBundle] loadNibNamed:@"WPAlertView" owner:self options:nil][0];
        }

        if (IS_IPAD) {
            CGFloat backgroundViewWidth = CGRectGetWidth(scrollView.frame) / 2.0f;
            CGFloat backgroundViewHeight = CGRectGetHeight(scrollView.frame) / 2.0f;
            CGFloat backgroundViewX = CGRectGetMidX(scrollView.frame) / 2.0f;
            CGFloat backgroundViewY = CGRectGetMidY(scrollView.frame) / 4.0f;
            backgroundView.frame = CGRectMake(backgroundViewX,
                                              backgroundViewY,
                                              backgroundViewWidth,
                                              backgroundViewHeight);
            backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                              UIViewAutoresizingFlexibleLeftMargin |
                                              UIViewAutoresizingFlexibleRightMargin;
        } else {
            backgroundView.frame = scrollView.frame;
            backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                              UIViewAutoresizingFlexibleHeight;
        }

        [self adjustTextFieldLabelWidths];
        [scrollView addSubview:backgroundView];

        [self configureView];
        [self configureBackgroundColor];
        [self configureButtonVisibility];
        [self configureTextFieldVisibility];
        [self addGestureRecognizer];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)setOverlayMode:(WPAlertViewOverlayMode)overlayMode
{
    if (_overlayMode != overlayMode) {
        _overlayMode = overlayMode;
        [self adjustOverlayDismissal];
        [self configureButtonVisibility];
        [self configureTextFieldVisibility];
        [self setNeedsUpdateConstraints];
    }
}

- (void)setOverlayTitle:(NSString *)overlayTitle
{
    if (_overlayTitle != overlayTitle) {
        _overlayTitle = overlayTitle;
        self.titleLabel.text = _overlayTitle;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setOverlayDescription:(NSString *)overlayDescription
{
    if (_overlayDescription != overlayDescription) {
        self.descriptionLabel.hidden = NO;
        _overlayDescription = overlayDescription;
        self.descriptionLabel.text = _overlayDescription;
        [self setNeedsUpdateConstraints];
    } else if (overlayDescription == nil) {
        self.descriptionLabel.hidden = YES;
    }
}

- (void)setFooterDescription:(NSString *)footerDescription
{
    if (_footerDescription != footerDescription) {
        _footerDescription = footerDescription;
        self.bottomLabel.text = _footerDescription;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setFirstTextFieldPlaceholder:(NSString *)firstTextFieldPlaceholder
{
    if (![_firstTextFieldPlaceholder isEqualToString:firstTextFieldPlaceholder]) {
        _firstTextFieldPlaceholder = firstTextFieldPlaceholder;
        self.firstTextField.placeholder = _firstTextFieldPlaceholder;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setFirstTextFieldValue:(NSString *)firstTextFieldValue
{
    if (![_firstTextFieldValue isEqualToString:firstTextFieldValue]) {
        _firstTextFieldValue = firstTextFieldValue;
        self.firstTextField.text = _firstTextFieldValue;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setFirstTextFieldLabelText:(NSString *)firstTextFieldLabelText
{
    if (![_firstTextFieldLabelText isEqualToString:firstTextFieldLabelText]) {
        _firstTextFieldLabelText = firstTextFieldLabelText;
        _firstTextFieldLabel.text = _firstTextFieldLabelText;
        [self adjustTextFieldLabelWidths];
        [self setNeedsUpdateConstraints];
    }
}

- (void)setSecondTextFieldPlaceholder:(NSString *)secondTextFieldPlaceholder
{
    if (![_secondTextFieldPlaceholder isEqualToString:secondTextFieldPlaceholder]) {
        _secondTextFieldPlaceholder = secondTextFieldPlaceholder;
        self.secondTextField.placeholder = _secondTextFieldPlaceholder;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setSecondTextFieldValue:(NSString *)secondTextFieldValue
{
    if (![_secondTextFieldValue isEqualToString:secondTextFieldValue]) {
        _secondTextFieldValue = secondTextFieldValue;
        self.secondTextField.text = _secondTextFieldValue;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setSecondTextFieldLabelText:(NSString *)secondTextFieldLabelText
{
    if (![_secondTextFieldLabelText isEqualToString:secondTextFieldLabelText]) {
        _secondTextFieldLabelText = secondTextFieldLabelText;
        _secondTextFieldLabel.text = _secondTextFieldLabelText;
        [self adjustTextFieldLabelWidths];
        [self setNeedsUpdateConstraints];
    }
}

- (void)setLeftButtonText:(NSString *)leftButtonText
{
    if (_leftButtonText != leftButtonText) {
        _leftButtonText = leftButtonText;
        [self.leftButton setTitle:_leftButtonText forState:UIControlStateNormal];
        [self needsUpdateConstraints];
    }
}

- (void)setRightButtonText:(NSString *)rightButtonText
{
    if (_rightButtonText != rightButtonText) {
        _rightButtonText = rightButtonText;
        [self.rightButton setTitle:_rightButtonText forState:UIControlStateNormal];
        [self setNeedsUpdateConstraints];
    }
}

- (void)setHideBackgroundView:(BOOL)hideBackgroundView
{
    if (_hideBackgroundView != hideBackgroundView) {
        _hideBackgroundView = hideBackgroundView;
        [self configureBackgroundColor];
        [self setNeedsUpdateConstraints];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self convertRect:keyboardRect fromView:nil];
    CGSize keyboardSize = keyboardRect.size;
    [self recalculateScrollViewContentSizeWithKeyboardSize:keyboardSize];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [self recalculateScrollViewContentSizeWithKeyboardSize:CGSizeZero];
}

- (void)recalculateScrollViewContentSizeWithKeyboardSize:(CGSize)keyboardSize
{
    if (CGSizeEqualToSize(keyboardSize, CGSizeZero)) {
        self.scrollView.contentSize = self.backgroundView.bounds.size;
        return;
    }

    // Make the scroll view scrollable when in landscape on the iPhone - the keyboard
    // covers up half of the view otherwise
    CGSize viewSize = self.backgroundView.bounds.size;
    CGRect buttonRect = [self convertRect:self.leftButton.frame fromView:self.leftButton];
    CGFloat buttonBottomY = buttonRect.origin.y + self.leftButton.frame.size.height;

    if (buttonBottomY > viewSize.height - keyboardSize.height) {
        viewSize.height += buttonBottomY - (viewSize.height - keyboardSize.height);
    }

    self.scrollView.contentSize = viewSize;

    CGRect rect = CGRectZero;
    if ([self.firstTextField isFirstResponder]) {
        rect = self.firstTextField.frame;
        rect = [self.scrollView convertRect:rect fromView:self.firstTextField];
    } else if ([self.secondTextField isFirstResponder]) {
        rect = self.secondTextField.frame;
        rect = [self.scrollView convertRect:rect fromView:self.secondTextField];
    }

    [self.scrollView scrollRectToVisible:rect animated:YES];
}

- (void)hideTitleAndDescription:(BOOL)hide
{
    if (hide == self.titleLabel.hidden) {
        return;
    }

    self.titleLabel.hidden = hide;
    self.descriptionLabel.hidden = hide;

    NSArray *constraints = self.backgroundView.constraints;
    if (hide) {

        for (NSLayoutConstraint *constraint in constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeTop && [constraint.firstItem isEqual:self.firstTextField] && [constraint.secondItem isKindOfClass:[UIImageView class]]) {
                self.originalFirstTextFieldConstraint = constraint;
                break;
            }
        }
        [self.backgroundView removeConstraint:self.originalFirstTextFieldConstraint];

        NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:self.firstTextField
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.backgroundView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:self.originalFirstTextFieldConstraint.multiplier
                                                                          constant:self.originalFirstTextFieldConstraint.constant];
        [self.backgroundView addConstraint:newConstraint];

    } else {

        for (NSLayoutConstraint *constraint in constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeTop && [constraint.firstItem isEqual:self.firstTextField] && [constraint.secondItem isEqual:self.backgroundView]) {
                [self.backgroundView removeConstraint:constraint];
                break;
            }
        }
        [self.backgroundView addConstraint:self.originalFirstTextFieldConstraint];
    }

    [self setNeedsUpdateConstraints];
}

#pragma mark - IBAction Methods

- (IBAction)clickedOnButton1
{
    if (self.button1CompletionBlock) {
        self.button1CompletionBlock(self);
    }
}

- (IBAction)clickedOnButton2
{
    if (self.button2CompletionBlock) {
        self.button2CompletionBlock(self);
    }
}

#pragma mark - Private Methods

- (void)configureBackgroundColor
{
    CGFloat alpha = 0.95;
    if (self.hideBackgroundView) {
        alpha = 1.0;
    }
    self.backgroundColor = [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:alpha];
    self.backgroundView.backgroundColor = [UIColor clearColor];
}

- (void)addGestureRecognizer
{
    _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnView:)];
    _gestureRecognizer.numberOfTapsRequired = 1;
    _gestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_gestureRecognizer];
}

- (void)configureView
{
    self.titleLabel.font = [WPFontManager openSansLightFontOfSize:25.0];
    self.descriptionLabel.font = [WPNUXUtility descriptionTextFont];
    self.bottomLabel.font = [WPFontManager openSansRegularFontOfSize:10.0];
}

- (void)configureButtonVisibility
{
    if (self.overlayMode == WPAlertViewOverlayModeTwoButtonMode ||
        self.overlayMode == WPAlertViewOverlayModeOneTextFieldTwoButtonMode ||
        self.overlayMode == WPAlertViewOverlayModeTwoTextFieldsTwoButtonMode ||
        self.overlayMode == WPAlertViewOverlayModeTwoTextFieldsSideBySideTwoButtonMode) {
        _leftButton.hidden = NO;
        _rightButton.hidden = NO;
    } else {
        _leftButton.hidden = YES;
        _rightButton.hidden = YES;
    }
}

- (void)configureTextFieldVisibility
{
    if (self.overlayMode == WPAlertViewOverlayModeOneTextFieldTwoButtonMode) {
        _firstTextField.hidden = NO;
        [_firstTextField becomeFirstResponder];
        _secondTextField.hidden = YES;
    } else if (self.overlayMode == WPAlertViewOverlayModeTwoTextFieldsTwoButtonMode ||
               self.overlayMode == WPAlertViewOverlayModeTwoTextFieldsSideBySideTwoButtonMode) {
        _firstTextField.hidden = NO;
        [_firstTextField becomeFirstResponder];
        _secondTextField.hidden = NO;
    } else {
        _firstTextField.hidden = YES;
        _secondTextField.hidden = YES;
    }
}

- (void)adjustOverlayDismissal
{
    if (self.overlayMode == WPAlertViewOverlayModeTapToDismiss) {
        _gestureRecognizer.numberOfTapsRequired = 1;
    } else if (self.overlayMode == WPAlertViewOverlayModeDoubleTapToDismiss) {
        _gestureRecognizer.numberOfTapsRequired = 2;
    } else {
        // This is for the two button mode, we still want the gesture recognizer to fire off
        // as it will redirect the button taps to the correct target. Plus we also enable
        // tap to dismiss for the two button mode.
        _gestureRecognizer.numberOfTapsRequired = 1;
    }
}

- (void)adjustTextFieldLabelWidths
{
    if (_firstTextFieldLabel.text.length == 0 && _secondTextFieldLabel.text.length == 0) {
        _firstTextFieldLabelWidthConstraint.constant = 0.0f;
    } else {
        _firstTextFieldLabelWidthConstraint.constant = WPAlertViewDefaultTextFieldLabelWidth;
    }
}

- (void)tappedOnView:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self];

    // To avoid accidentally dismissing the view when the user was trying to tap one of the buttons,
    // add some padding around the button frames.
    CGRect button1Frame = CGRectInset([self.leftButton convertRect:self.leftButton.frame toView:self], -2 * WPAlertViewStandardOffset, -WPAlertViewStandardOffset);
    CGRect button2Frame = CGRectInset([self.rightButton convertRect:self.rightButton.frame toView:self], -2 * WPAlertViewStandardOffset, -WPAlertViewStandardOffset);

    BOOL touchedButton1 = CGRectContainsPoint(button1Frame, touchPoint);
    BOOL touchedButton2 = CGRectContainsPoint(button2Frame, touchPoint);

    if (touchedButton1 || touchedButton2) {
        return;
    }

    if ([self.firstTextField isFirstResponder]) {
        [self.firstTextField resignFirstResponder];
    }
    if ([self.secondTextField isFirstResponder]) {
        [self.secondTextField resignFirstResponder];
    }

    if (gestureRecognizer.numberOfTapsRequired == 1) {
        if (self.singleTapCompletionBlock) {
            self.singleTapCompletionBlock(self);
        }
    } else if (gestureRecognizer.numberOfTapsRequired == 2) {
        if (self.doubleTapCompletionBlock) {
            self.doubleTapCompletionBlock(self);
        }
    }
}

- (void)dismiss
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self removeFromSuperview];
                         }
                     }
     ];
}

#pragma mark - UITextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.firstTextField]) {
        [self.secondTextField becomeFirstResponder];
    } else {
        [self clickedOnButton2];
    }
    return NO;
}

@end
