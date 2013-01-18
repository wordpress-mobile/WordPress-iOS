//
//  WPFriendFinderNudgeView.m
//  WordPress
//
//  Created by Beau Collins on 7/3/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WPFriendFinderNudgeView.h"

float const WPFriendFinderNudgeViewHeight  = 44.f;
float const WPFriendFinderNudgeViewPadding = 5.f;
float const WPFriendFinderNudgeViewCancelButtonWidth = 46.f;

@interface WPFriendFinderNudgeView ()
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) CAGradientLayer *gradientHighlight;
@end

@implementation WPFriendFinderNudgeView

@synthesize confirmButton, cancelButton, gradient, gradientHighlight;

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]){
                
        frame.size.height = WPFriendFinderNudgeViewHeight;
        self.frame = frame;
        self.backgroundColor = [UIColor colorWithRed:33.0/255.0 green:117.0/255.0 blue:155.0/255.0 alpha:0.95f];
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self addSubview:self.confirmButton];
        [self addSubview:self.cancelButton];
        
        
        // Layout the cancel button
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        CGRect cancelFrame = CGRectMake(frame.size.width - WPFriendFinderNudgeViewCancelButtonWidth - 1.0f, 0.f, WPFriendFinderNudgeViewCancelButtonWidth, self.frame.size.height - 1.0f);
        self.cancelButton.frame = cancelFrame;
        
        // Layout the confirm button
        self.confirmButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CGRect confirmFrame = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
        self.confirmButton.frame = confirmFrame;
        
        self.confirmButton.titleLabel.shadowOffset = CGSizeMake(0.f, -1.f);
        self.confirmButton.titleLabel.shadowColor = [UIColor UIColorFromHex:0x163948];
        
        self.confirmButton.titleEdgeInsets = UIEdgeInsetsMake(10.f, 20.f, 10.f, 10.f + WPFriendFinderNudgeViewCancelButtonWidth);
        self.confirmButton.imageEdgeInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 5.f);
        
        self.confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        [self.confirmButton setTitleColor:[UIColor colorWithWhite:1.f alpha:0.75f] forState:UIControlStateNormal];
        //[self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        
        // Prepare the view states
        [self.confirmButton setTitle:NSLocalizedString(@"Find Friends to Follow", @"Nudge to open the Friend Finder view") forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [self.confirmButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
        
        [self.confirmButton setImage:[UIImage imageNamed:@"friend_follow_service_icons"] forState:UIControlStateNormal];
                
        [self.cancelButton setImage:[UIImage imageNamed:@"friend_finder_cancel_btn"] forState:UIControlStateNormal];
        [self.cancelButton setImage:[UIImage imageNamed:@"friend_finder_cancel_btn_highlight"] forState:UIControlStateHighlighted];
        [self.cancelButton setAccessibilityLabel:NSLocalizedString(@"Dismiss Friend Finder", @"")];
        
        self.cancelButton.adjustsImageWhenHighlighted = NO;
        
        // top highlight
        CGRect highlightFrame = CGRectMake(0.0f, 0.0f, frame.size.width, 2.0f);
        self.gradientHighlight = [CAGradientLayer layer];
        self.gradientHighlight.frame = highlightFrame;
        self.gradientHighlight.colors = [NSArray arrayWithObjects:
                                (id)[[[UIColor whiteColor] colorWithAlphaComponent:0.25f] CGColor],
                                (id)[[[UIColor whiteColor] colorWithAlphaComponent:0.0f] CGColor],
                                nil];
        self.gradientHighlight.startPoint = CGPointMake(0.f, 0.f);
        self.gradientHighlight.endPoint = CGPointMake(0.f, 1.f);
        self.gradientHighlight.needsDisplayOnBoundsChange = YES;
        [self.layer addSublayer:gradientHighlight];
        
        
        // shadow
        CGRect gradientFrame = CGRectMake(0.0f, -4.0f, frame.size.width, 4.0f);
        self.gradient = [CAGradientLayer layer];
        self.gradient.frame = gradientFrame;
        self.gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor clearColor] CGColor],
                           (id)[[[UIColor blackColor] colorWithAlphaComponent:0.1f] CGColor],
                           nil];
        self.gradient.startPoint = CGPointMake(0.f, 0.f);
        self.gradient.endPoint = CGPointMake(0.f, 1.f);
        self.gradient.needsDisplayOnBoundsChange = YES;
        [self.layer addSublayer:gradient];
    }
    return self;
}


- (void) layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.gradient.frame;
    frame.size.width = self.frame.size.width;
    self.gradient.frame = frame;
    CGRect frameHighlight = self.gradientHighlight.frame;
    frameHighlight.size.width = self.frame.size.width;
    self.gradientHighlight.frame = frameHighlight;
}

@end
