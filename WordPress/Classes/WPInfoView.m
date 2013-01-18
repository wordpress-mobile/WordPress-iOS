//
//  WPInfoView.m
//  WordPress
//
//  Created by Eric Johnson on 8/30/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPInfoView.h"
#import <QuartzCore/QuartzCore.h>

@implementation WPInfoView

@synthesize titleLabel;
@synthesize messageLabel;
@synthesize cancelButton;

#pragma mark -
#pragma mark Lifecycle Methods

+ (WPInfoView *)WPInfoViewWithTitle:(NSString *)titleText message:(NSString *)messageText cancelButton:(NSString *)cancelText {
    NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"WPInfoView" owner:nil options:nil];
    WPInfoView *view = [arr objectAtIndex:0];
    [view setTitle:titleText message:messageText cancelButton:cancelText];
    
    return view;
}


- (void)didMoveToSuperview {
    [self centerInSuperview];
}


#pragma mark -
#pragma mark Instance Methods

- (IBAction)handleCancelButtonTapped:(id)sender { 
    // Prevent multiple taps.
    [cancelButton removeTarget:self action:@selector(handleCancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


- (void)setTitle:(NSString *)titleText message:(NSString *)messageText cancelButton:(NSString *)cancelText {
    self.titleLabel.text = titleText;
    self.messageLabel.text = messageText;
    [self.cancelButton setTitle:cancelText forState:UIControlStateNormal];

    CGSize sz = [messageText sizeWithFont:messageLabel.font
                        constrainedToSize:CGSizeMake(self.frame.size.width, 999.0f)
                            lineBreakMode:NSLineBreakByWordWrapping];
    
    CGRect lfrm = self.messageLabel.frame;
    lfrm.size.height = sz.height;
    self.messageLabel.frame = lfrm;
    
    CGRect bfrm = self.cancelButton.frame;
    bfrm.origin.y = lfrm.origin.y + lfrm.size.height + 10.0f;
    self.cancelButton.frame = bfrm;
    
    if ((cancelText == nil || [cancelText length] == 0) && !self.cancelButton.hidden) {
        self.cancelButton.hidden = YES;
        CGRect frame = self.frame;
        frame.size.height = lfrm.origin.y + lfrm.size.height + 10.0f;
        self.frame = frame;
        
    } else if(self.cancelButton.hidden) {
        self.cancelButton.hidden = NO;
        CGRect frame = self.frame;
        frame.size.height = bfrm.origin.y + bfrm.size.height + 10.0f;
        self.frame = frame;
    }
    
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
    CGFloat x = (frame.size.width / 2.0f) - (self.frame.size.width / 2.0f);
    CGFloat y = 75.0f;//(frame.size.height / 2.0f) - (self.frame.size.height / 2.0f);
    
    frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}

@end
