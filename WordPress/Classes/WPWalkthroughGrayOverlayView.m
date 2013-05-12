//
//  WPWalkthroughGrayOverlayView.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPWalkthroughGrayOverlayView.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"

@interface WPWalkthroughGrayOverlayView() {
    UIImageView *_logo;
    UILabel *_title;
    UILabel *_description;
    UILabel *_bottomLabel;
    UIImageView *_topSeparator;
    UIImageView *_bottomSeparator;
    WPNUXSecondaryButton *_button1;
    WPNUXPrimaryButton *_button2;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    
    UITapGestureRecognizer *_gestureRecognizer;
}

@end

@implementation WPWalkthroughGrayOverlayView

NSUInteger const WPWalkthroughGrayOverlayIconVerticalOffset = 75.0;
NSUInteger const WPWalkthroughGrayOverlayStandardOffset = 16.0;
NSUInteger const WPWalkthroughGrayOverlayBottomLabelOffset = 91.0;
NSUInteger const WPWalkthroughGrayOverlayBottomPanelHeight = 64.0;
NSUInteger const WPWalkthroughGrayOverlayMaxLabelWidth = 289.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
        [self configureBackgroundColor];
        [self addViewElements];
        [self addGestureRecognizer];
    }
    return self;
}

- (void)setOverlayMode:(WPWalkthroughGrayOverlayViewOverlayMode)overlayMode
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

- (void)setButton1Text:(NSString *)button1Text
{
    if (_button1Text != button1Text) {
        _button1Text = button1Text;
        [_button1 setTitle:_button1Text forState:UIControlStateNormal];
        [_button1 sizeToFit];
        [self setNeedsLayout];
    }
}

- (void)setButton2Text:(NSString *)button2Text
{
    if (_button2Text != button2Text) {
        _button2Text = button2Text;
        [_button2 setTitle:_button2Text forState:UIControlStateNormal];
        [_button2 sizeToFit];
        [self setNeedsLayout];
    }
}

- (void)setIcon:(WPWalkthroughGrayOverlayViewIcon)icon
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
    CGSize titleSize = [_title.text sizeWithFont:_title.font constrainedToSize:CGSizeMake(WPWalkthroughGrayOverlayMaxLabelWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    y = CGRectGetMaxY(_logo.frame) + 0.5*WPWalkthroughGrayOverlayStandardOffset;
    _title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = WPWalkthroughGrayOverlayStandardOffset;
    y = CGRectGetMaxY(_title.frame) + WPWalkthroughGrayOverlayStandardOffset;
    _topSeparator.frame = CGRectMake(x, y, _viewWidth-2*WPWalkthroughGrayOverlayStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_description.text sizeWithFont:_description.font constrainedToSize:CGSizeMake(WPWalkthroughGrayOverlayMaxLabelWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    y = CGRectGetMaxY(_topSeparator.frame) + 0.5*WPWalkthroughGrayOverlayStandardOffset;
    _description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = WPWalkthroughGrayOverlayStandardOffset;
    y = CGRectGetMaxY(_description.frame) + 0.5*WPWalkthroughGrayOverlayStandardOffset;
    _bottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*WPWalkthroughGrayOverlayStandardOffset, 2);
    
    // Layout Bottom Label
    CGSize bottomLabelSize = [_bottomLabel.text sizeWithFont:_bottomLabel.font];
    x = (_viewWidth - bottomLabelSize.width)/2.0;
    y = _viewHeight - WPWalkthroughGrayOverlayBottomLabelOffset;
    _bottomLabel.frame = CGRectIntegral(CGRectMake(x, y, bottomLabelSize.width, bottomLabelSize.height));
    
    // Layout Bottom Buttons
    if (self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode) {
        x = WPWalkthroughGrayOverlayStandardOffset;
        y = (_viewHeight - WPWalkthroughGrayOverlayBottomPanelHeight + WPWalkthroughGrayOverlayStandardOffset);
        _button1.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_button1.frame), CGRectGetHeight(_button1.frame)));
        
        x = _viewWidth - CGRectGetWidth(_button2.frame) - WPWalkthroughGrayOverlayStandardOffset;
        y = CGRectGetMinY(_button1.frame);
        _button2.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_button2.frame), CGRectGetHeight(_button2.frame)));
    } else {
        _button1.frame = CGRectZero;
        _button2.frame = CGRectZero;
    }
    
    // TODO: Combine this with the same code in BaseNUXViewController
    NSArray *viewsToCenter = @[_logo, _title, _description, _topSeparator, _description, _bottomLabel];
    CGFloat heightOfControls = CGRectGetMaxY(_bottomLabel.frame) - CGRectGetMinY(_logo.frame);
    CGFloat startingYForCenteredControls = floorf((_viewHeight - heightOfControls)/2.0);
    CGFloat offsetToCenter = CGRectGetMinY(_logo.frame) - startingYForCenteredControls;
    
    for (UIControl *control in viewsToCenter) {
        CGRect frame = control.frame;
        frame.origin.y -= offsetToCenter;
        control.frame = frame;
    }
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
    _title.textAlignment = UITextAlignmentCenter;
    _title.numberOfLines = 0;
    _title.lineBreakMode = UILineBreakModeWordWrap;
    _title.font = [UIFont fontWithName:@"OpenSans-Light" size:29];
    _title.text = self.overlayTitle;
    _title.shadowColor = [UIColor blackColor];
    _title.shadowOffset = CGSizeMake(1.0, 1.0);
    _title.textColor = [UIColor whiteColor];
    [self addSubview:_title];
    
    // Add Top Separator
    _topSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line-dark"]];
    [self addSubview:_topSeparator];
    
    // Add Description
    _description = [[UILabel alloc] init];
    _description.backgroundColor = [UIColor clearColor];
    _description.textAlignment = UITextAlignmentCenter;
    _description.numberOfLines = 0;
    _description.lineBreakMode = UILineBreakModeWordWrap;
    _description.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    _description.text = self.overlayDescription;
    _description.shadowColor = [UIColor blackColor];
    _description.textColor = [UIColor whiteColor];
    [self addSubview:_description];
    
    // Add Bottom Separator
    _bottomSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line-dark"]];
    [self addSubview:_bottomSeparator];
    
    // Add Bottom Label
    _bottomLabel = [[UILabel alloc] init];
    _bottomLabel.backgroundColor = [UIColor clearColor];
    _bottomLabel.textAlignment = UITextAlignmentCenter;
    _bottomLabel.numberOfLines = 1;
    _bottomLabel.font = [UIFont fontWithName:@"OpenSans" size:10.0];
    _bottomLabel.text = self.footerDescription;
    _bottomLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
    [self addSubview:_bottomLabel];
    
    // Add Button 1
    _button1 = [[WPNUXSecondaryButton alloc] init];
    [_button1 setTitle:self.button1Text forState:UIControlStateNormal];
    [_button1 sizeToFit];
    [_button1 addTarget:self action:@selector(clickedOnButton1) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_button1];
    
    // Add Button 2
    _button2 = [[WPNUXPrimaryButton alloc] init];
    [_button2 setTitle:self.button2Text forState:UIControlStateNormal];
    [_button2 sizeToFit];
    [_button2 addTarget:self action:@selector(clickedOnButton2) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_button2];
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
    if (self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss) {
        _gestureRecognizer.numberOfTapsRequired = 1;
    } else if (self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModeDoubleTapToDismiss) {
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
    BOOL touchedButton1 = CGRectContainsPoint(_button1.frame, touchPoint);
    BOOL touchedButton2 = CGRectContainsPoint(_button2.frame, touchPoint);
    
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

- (void)clickedOnButton1
{
    if (self.button1CompletionBlock) {
        self.button1CompletionBlock(self);
    }
}

- (void)clickedOnButton2
{
    if (self.button2CompletionBlock) {
        self.button2CompletionBlock(self);
    }
}

@end
