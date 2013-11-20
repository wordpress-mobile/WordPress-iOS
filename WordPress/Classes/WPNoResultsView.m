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
    
    // On iOS 7, scroll view content insets can be automatically managed
    // by their view controller. Calling [self centerInSuperview] via GDC
    // allows the centering of the view to be done after the parent view
    // controller has had its content insets adjusted
    dispatch_async(dispatch_get_main_queue(), ^{
        [self centerInSuperview];
    });
}

#pragma mark Instance Methods


- (void)setupWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView {
    
    CGFloat width = 270.0;
    
    [self addSubview:accessoryView];
    
    // setup title label
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
    
    
    // Layout views
    accessoryView.frame = CGRectMake((width - CGRectGetWidth(accessoryView.frame)) / 2, 0, CGRectGetWidth(accessoryView.frame), CGRectGetHeight(accessoryView.frame));
    
    CGSize titleSize = [_titleLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _titleLabel.font} context:nil].size;
    _titleLabel.frame = CGRectMake(0, (CGRectGetMaxY(accessoryView.frame) > 0 ? CGRectGetMaxY(accessoryView.frame) + 10.0 : 0) , width, titleSize.height);
    
    CGSize messageSize = [_messageLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _messageLabel.font} context:nil].size;
    _messageLabel.frame = CGRectMake(0, CGRectGetMaxY(_titleLabel.frame) + 10.0, width, messageSize.height);
    
    
    CGRect bottomViewRect;
    if (messageText.length > 0) {
        bottomViewRect = _messageLabel.frame;
    } else if (titleText.length > 0) {
        bottomViewRect = _titleLabel.frame;
    } else {
        bottomViewRect = accessoryView.frame;
    }
    
    CGRect viewFrame = CGRectMake(0, 0, width, CGRectGetMaxY(bottomViewRect));
    self.frame = viewFrame;

    if ([self superview]) {
        [self centerInSuperview];
    }
}


- (void)showInView:(UIView *)view {
    [view addSubview:self];
    [view bringSubviewToFront:self];
}


- (void)centerInSuperview {
    // Center in parent.
    CGRect frame = [self superview].frame;
    CGFloat x = (CGRectGetWidth(frame) - CGRectGetWidth(self.frame))/2.0;
    CGFloat y = ((CGRectGetHeight(frame)) - CGRectGetHeight(self.frame))/2.0;
    
    frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}

@end
