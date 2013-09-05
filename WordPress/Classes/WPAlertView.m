//  NewWPWalkthroughOverlayView.m
//  WordPress
//
//  Created by Aaron Douglas on 9/5/2013
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPAlertView.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPNUXUtility.h"

@interface WPAlertView() {
    UITapGestureRecognizer *_gestureRecognizer;
    NSArray *_horizontalConstraints;
    NSArray *_verticalConstraints;
}

@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UIImageView *bottomSeparator;
@property (nonatomic, weak) IBOutlet UILabel *bottomLabel;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet WPNUXSecondaryButton *leftButton;
@property (nonatomic, weak) IBOutlet WPNUXPrimaryButton *rightButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;

@end

@implementation WPAlertView

CGFloat const WPAlertViewStandardOffset = 16.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _overlayMode = WPAlertViewOverlayModeTapToDismiss;
        _verticalConstraints = [NSArray array];
        _horizontalConstraints = [NSArray array];
        
        UIView *overlayView = [[NSBundle mainBundle] loadNibNamed:@"WPAlertView" owner:self options:nil][0];
        overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:overlayView];
        
        [self configureView];
        [self configureBackgroundColor];
        [self configureButtonVisibility];
        [self addGestureRecognizer];
    }
    return self;
}

- (void)setOverlayMode:(WPAlertViewOverlayMode)overlayMode
{
    if (_overlayMode != overlayMode) {
        _overlayMode = overlayMode;
        [self adjustOverlayDismissal];
        [self configureButtonVisibility];
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
        _overlayDescription = overlayDescription;
        self.descriptionLabel.text = _overlayDescription;
        [self setNeedsUpdateConstraints];
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
        self.textField.hidden = NO;
        _firstTextFieldPlaceholder = firstTextFieldPlaceholder;
        self.textField.placeholder = _firstTextFieldPlaceholder;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setFirstTextFieldValue:(NSString *)firstTextFieldValue
{
    if (![_firstTextFieldValue isEqualToString:firstTextFieldValue]) {
        self.textField.hidden = NO;
        _firstTextFieldValue = firstTextFieldValue;
        self.textField.text = _firstTextFieldValue;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setSecondTextFieldPlaceholder:(NSString *)secondTextFieldPlaceholder
{
    if (![_secondTextFieldPlaceholder isEqualToString:secondTextFieldPlaceholder]) {
        self.textField.hidden = NO;
        _secondTextFieldPlaceholder = secondTextFieldPlaceholder;
        self.textField.text = _secondTextFieldPlaceholder;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setSecondTextFieldValue:(NSString *)secondTextFieldValue
{
    if (![_secondTextFieldValue isEqualToString:secondTextFieldValue]) {
        self.textField.hidden = NO;
        _secondTextFieldValue = secondTextFieldValue;
        self.textField.text = _secondTextFieldValue;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)updateConstraints
{
    [super updateConstraints];

    [self removeConstraints:_verticalConstraints];
    [self removeConstraints:_horizontalConstraints];
    
    UIView *backgroundView = self.backgroundView;
    NSDictionary *views = NSDictionaryOfVariableBindings(backgroundView);
    _horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:0 metrics:0 views:views];
    _verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|" options:0 metrics:0 views:views];
    [self addConstraints:_horizontalConstraints];
    [self addConstraints:_verticalConstraints];
    
    // Center Views
    CGFloat heightOfMiddleControls = CGRectGetMaxY(self.bottomSeparator.frame);// - CGRectGetMinY(self.logo.frame);
    CGFloat verticalOffset = (CGRectGetMaxY(self.bottomLabel.frame) - heightOfMiddleControls)/2.0;
    self.verticalCenteringConstraint.constant = verticalOffset;
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
    self.backgroundView.backgroundColor = [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:alpha];
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
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:25.0];
    self.descriptionLabel.font = [WPNUXUtility descriptionTextFont];
    self.bottomLabel.font = [UIFont fontWithName:@"OpenSans" size:10.0];
}

- (void)configureButtonVisibility
{
    if (self.overlayMode == WPAlertViewOverlayModeTwoButtonMode) {
        _leftButton.hidden = NO;
        _rightButton.hidden = NO;
    } else {
        _leftButton.hidden = YES;
        _rightButton.hidden = YES;
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


- (void)tappedOnView:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    
    // To avoid accidentally dismissing the view when the user was trying to tap one of the buttons,
    // add some padding around the button frames.
    CGRect button1Frame = CGRectInset([self.leftButton convertRect:self.leftButton.frame toView:self], -2 * WPAlertViewStandardOffset, -WPAlertViewStandardOffset);
    CGRect button2Frame = CGRectInset([self.rightButton convertRect:self.rightButton.frame toView:self], -2 * WPAlertViewStandardOffset, -WPAlertViewStandardOffset);
    
    BOOL touchedButton1 = CGRectContainsPoint(button1Frame, touchPoint);
    BOOL touchedButton2 = CGRectContainsPoint(button2Frame, touchPoint);
    
    if (touchedButton1 || touchedButton2)
        return;
    
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
    [self removeFromSuperview];
}

@end
