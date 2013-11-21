//
//  WPInfoView.m
//  WordPress
//
//  Created by Eric Johnson on 8/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPNoResultsView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPStyleGuide.h"

@implementation WPNoResultsView

#pragma mark -
#pragma mark Lifecycle Methods

+ (WPNoResultsView *)noResultsViewWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView {
    
    WPNoResultsView *view = [[WPNoResultsView alloc] init];
    [view setupWithTitle:titleText message:messageText accessoryView:accessoryView];
    
    return view;
}

- (void)didMoveToSuperview {
    [self centerInSuperview];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    
    CGFloat width = 270.0;
    
    // Layout views
    _accessoryView.frame = CGRectMake((width - CGRectGetWidth(_accessoryView.frame)) / 2, 0, CGRectGetWidth(_accessoryView.frame), CGRectGetHeight(_accessoryView.frame));
    
    CGSize titleSize = [_titleLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _titleLabel.font} context:nil].size;
    _titleLabel.frame = CGRectMake(0, (CGRectGetMaxY(_accessoryView.frame) > 0 && _accessoryView.hidden != YES ? CGRectGetMaxY(_accessoryView.frame) + 10.0 : 0) , width, titleSize.height);
    
    CGSize messageSize = [_messageLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _messageLabel.font} context:nil].size;
    _messageLabel.frame = CGRectMake(0, CGRectGetMaxY(_titleLabel.frame) + 10.0, width, messageSize.height);
    
    
    CGRect bottomViewRect;
    if (_messageLabel.text.length > 0) {
        bottomViewRect = _messageLabel.frame;
    } else if (_titleLabel.text.length > 0) {
        bottomViewRect = _titleLabel.frame;
    } else {
        bottomViewRect = _accessoryView.frame;
    }
    
    CGRect viewFrame = CGRectMake(0, 0, width, CGRectGetMaxY(bottomViewRect));
    self.frame = viewFrame;
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    if ([self superview]) {
        [self centerInSuperview];
    }
}

#pragma mark Instance Methods

- (void)setupWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView {
    
    [self addSubview:accessoryView];
    
    // Stup Accessory View
    _accessoryView = accessoryView;
    
    // Setup title label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:24];
    _titleLabel.textColor = [WPStyleGuide whisperGrey];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.text = titleText;
    _titleLabel.numberOfLines = 0;
    [self addSubview:_titleLabel];
    
    // Setup message text
    _messageLabel = [[UILabel alloc] init];
    _messageLabel.font = [WPStyleGuide regularTextFont];
    _messageLabel.textColor = [WPStyleGuide whisperGrey];
    _messageLabel.text = messageText;
    _messageLabel.numberOfLines = 0;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_messageLabel];
    
    
    // Register for orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self setNeedsLayout];
}

- (void)showInView:(UIView *)view {
    [view addSubview:self];
    [view bringSubviewToFront:self];
}

- (void)centerInSuperview {
    // Center in parent
    CGRect frame = [self superview].frame;
    CGFloat x = (CGRectGetWidth(frame) - CGRectGetWidth(self.frame))/2.0;
    CGFloat y = ((CGRectGetHeight(frame)) - CGRectGetHeight(self.frame))/2.0;
    
    frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}

- (void)orientationDidChange:(NSNotification *)notification {
    
    UIDevice *device = notification.object;

    // hide the accessory view in landscape orientation on iPhone to help
    // ensure entire view fits on screen
    if (UIDeviceOrientationIsLandscape(device.orientation) && IS_IPHONE) {
        _accessoryView.hidden = YES;
    } else {
        _accessoryView.hidden = NO;
    }
    [self setNeedsLayout];
}

@end
