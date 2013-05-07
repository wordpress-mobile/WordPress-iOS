//
//  WPWalkthroughGrayOverlayView.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPWalkthroughGrayOverlayView.h"
#import "WPWalkthroughLineSeparatorView.h"
#import "WPWalkthroughButton.h"

@interface WPWalkthroughGrayOverlayView() {
    UILabel *_logo;
    UILabel *_title;
    UILabel *_description;
    UILabel *_bottomLabel;
    WPWalkthroughLineSeparatorView *_topSeparator;
    WPWalkthroughLineSeparatorView *_bottomSeparator;
    WPWalkthroughButton *_button1;
    WPWalkthroughButton *_button2;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    CGFloat _extraIconSpaceOnTop;
    CGFloat _extraIconSpaceOnBottom;
    
    UITapGestureRecognizer *_gestureRecognizer;
}

@end

@implementation WPWalkthroughGrayOverlayView

NSUInteger const WPWalkthroughGrayOverlayIconVerticalOffset = 75.0;
NSUInteger const WPWalkthroughGrayOverlayStandardOffset = 16.0;
NSUInteger const WPWalkthroughGrayOverlayBottomLabelOffset = 91.0;
NSUInteger const WPWalkthroughGrayOverlayBottomPanelHeight = 64.0;
NSUInteger const WPWalkthroughGrayOverlayBottomButtonWidth = 136.0;
NSUInteger const WPWalkthroughGrayOverlayBottomButtonHeight = 32.0;
NSUInteger const WPWalkthroughGrayOverlayMaxLabelWidth = 289.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
        [self configureBackgroundColor];
        [self configureIcon];
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
        _button1.text = _button1Text;
        [self setNeedsLayout];
    }
}

- (void)setButton2Text:(NSString *)button2Text
{
    if (_button2Text != button2Text) {
        _button2Text = button2Text;
        _button2.text = _button2Text;
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
    [_logo sizeToFit];
    x = (_viewWidth - CGRectGetWidth(_logo.frame))/2.0;
    y = WPWalkthroughGrayOverlayIconVerticalOffset - _extraIconSpaceOnTop;
    _logo.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_logo.frame), CGRectGetHeight(_logo.frame)));
    
    // Layout Title
    CGSize titleSize = [_title.text sizeWithFont:_title.font constrainedToSize:CGSizeMake(WPWalkthroughGrayOverlayMaxLabelWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    y = CGRectGetMaxY(_logo.frame) + 2*WPWalkthroughGrayOverlayStandardOffset - _extraIconSpaceOnBottom;
    _title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = WPWalkthroughGrayOverlayStandardOffset;
    y = CGRectGetMaxY(_title.frame) + 2*WPWalkthroughGrayOverlayStandardOffset;
    _topSeparator.frame = CGRectMake(x, y, _viewWidth-2*WPWalkthroughGrayOverlayStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_description.text sizeWithFont:_description.font constrainedToSize:CGSizeMake(WPWalkthroughGrayOverlayMaxLabelWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    y = CGRectGetMaxY(_topSeparator.frame) + WPWalkthroughGrayOverlayStandardOffset;
    _description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = WPWalkthroughGrayOverlayStandardOffset;
    y = CGRectGetMaxY(_description.frame) + WPWalkthroughGrayOverlayStandardOffset;
    _bottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*WPWalkthroughGrayOverlayStandardOffset, 2);
    
    // Layout Bottom Label
    CGSize bottomLabelSize = [_bottomLabel.text sizeWithFont:_bottomLabel.font];
    x = (_viewWidth - bottomLabelSize.width)/2.0;
    y = _viewHeight - WPWalkthroughGrayOverlayBottomLabelOffset;
    _bottomLabel.frame = CGRectIntegral(CGRectMake(x, y, bottomLabelSize.width, bottomLabelSize.height));
    
    // Layout Bottom Buttons
    if (self.overlayMode == WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode) {
        x = (_viewWidth - 2*WPWalkthroughGrayOverlayBottomButtonWidth - WPWalkthroughGrayOverlayStandardOffset)/2.0;
        y = (_viewHeight - WPWalkthroughGrayOverlayBottomPanelHeight + WPWalkthroughGrayOverlayStandardOffset);
        _button1.frame = CGRectIntegral(CGRectMake(x, y, WPWalkthroughGrayOverlayBottomButtonWidth, WPWalkthroughGrayOverlayBottomButtonHeight));
        
        x = CGRectGetMaxX(_button1.frame) + WPWalkthroughGrayOverlayStandardOffset;
        y = CGRectGetMinY(_button1.frame);
        _button2.frame = CGRectIntegral(CGRectMake(x, y, WPWalkthroughGrayOverlayBottomButtonWidth, WPWalkthroughGrayOverlayBottomButtonHeight));
    } else {
        _button1.frame = CGRectZero;
        _button2.frame = CGRectZero;
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
    self.backgroundColor = [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:42.0/255.0 alpha:alpha];
}

- (void)addGestureRecognizer
{
    _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnView:)];
    _gestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:_gestureRecognizer];
}

- (void)addViewElements
{
    // Add Icon
    _logo = [[UILabel alloc] init];
    _logo.backgroundColor = [UIColor clearColor];
    [self configureIcon];
    [_logo sizeToFit];
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
    _topSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
    _topSeparator.topLineColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    _topSeparator.bottomLineColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.1];
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
    _bottomSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
    _bottomSeparator.topLineColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    _bottomSeparator.bottomLineColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.1];
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
    _button1 = [[WPWalkthroughButton alloc] init];
    _button1.buttonColor = WPWalkthroughButtonGray;
    _button1.text = self.button1Text;
    [self addSubview:_button1];
    
    // Add Button 2
    _button2 = [[WPWalkthroughButton alloc] init];
    _button2.buttonColor = WPWalkthroughButtonGray;
    _button2.text = self.button2Text;
    [self addSubview:_button2];
}

- (void)configureIcon
{
    if (self.icon == WPWalkthroughGrayOverlayViewWarningIcon) {
        // WordPress Logo
        _logo.font = [UIFont fontWithName:@"Genericons-Regular" size:60];
        _logo.text = @"";
        _logo.textColor = [UIColor whiteColor];
        _extraIconSpaceOnTop = 20;
        _extraIconSpaceOnBottom = 33;
    } else {
        // Blue Checkmark
        _logo.font = [UIFont fontWithName:@"Genericons-Regular" size:110];
        _logo.text = @"";
        _logo.textColor = [UIColor colorWithRed:120.0/255.0 green:200/255.0 blue:230.0/255.0 alpha:1.0];
        _extraIconSpaceOnTop = 56;
        _extraIconSpaceOnBottom = 89;
    }
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
    if (touchedButton1) {
        [self clickedOnButton1];
    } else if (touchedButton2) {
        [self clickedOnButton2];
    } else {
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
