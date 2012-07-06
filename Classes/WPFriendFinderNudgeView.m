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
@property (nonatomic, retain) CAGradientLayer *gradient;
@end

@implementation WPFriendFinderNudgeView

@synthesize confirmButton, cancelButton, gradient;

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]){
                
        frame.size.height = WPFriendFinderNudgeViewHeight;
        self.frame = frame;
        self.backgroundColor = [UIColor colorWithRed:0.843f green:0.357f blue:0.192f alpha:0.95f];
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self addSubview:self.confirmButton];
        [self addSubview:self.cancelButton];
        
        
        // Layout the cancel button
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        CGRect cancelFrame = CGRectMake(frame.size.width - WPFriendFinderNudgeViewCancelButtonWidth, 0.f, WPFriendFinderNudgeViewCancelButtonWidth, self.frame.size.height);
        self.cancelButton.frame = cancelFrame;
        
        // Layout the confirm button
        self.confirmButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CGRect confirmFrame = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
        self.confirmButton.frame = confirmFrame;
        
        self.confirmButton.titleLabel.shadowOffset = CGSizeMake(0.f, -1.f);
        self.confirmButton.titleLabel.shadowColor = [UIColor blackColor];
        
        self.confirmButton.titleEdgeInsets = UIEdgeInsetsMake(10.f, 20.f, 10.f, 10.f + WPFriendFinderNudgeViewCancelButtonWidth);
        self.confirmButton.imageEdgeInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 5.f);
        
        self.confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        [self.confirmButton setTitleColor:[UIColor colorWithWhite:1.f alpha:0.75f] forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        
        // Prepare the view states
        [self.confirmButton setTitle:NSLocalizedString(@"Find Friends to Follow", @"Nudge to open the Friend Finder view") forState:UIControlStateNormal];
        [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [self.confirmButton setImage:[UIImage imageNamed:@"friend_follow_service_icons"] forState:UIControlStateNormal];
                
        [self.cancelButton setImage:[UIImage imageNamed:@"friend_finder_cancel_btn"] forState:UIControlStateNormal];
        [self.cancelButton setImage:[UIImage imageNamed:@"friend_finder_cancel_btn_highlight"] forState:UIControlStateHighlighted];
        
        self.cancelButton.adjustsImageWhenHighlighted = NO;
        
        // shadow
        CGRect gradientFrame = CGRectMake(0.f, -3.f, frame.size.width, 3.f);
        self.gradient = [CAGradientLayer layer];
        self.gradient.frame = gradientFrame;
        self.gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor clearColor] CGColor],
                           (id)[[[UIColor blackColor] colorWithAlphaComponent:0.5f] CGColor],
                           nil];
        self.gradient.startPoint = CGPointMake(0.f, 0.f);
        self.gradient.endPoint = CGPointMake(0.f, 1.f);
        self.gradient.needsDisplayOnBoundsChange = YES;
        [self.layer addSublayer:gradient];
    }
    return self;
}

- (void) dealloc {
    self.gradient = nil;
    [super dealloc];
}

- (void) layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.gradient.frame;
    frame.size.width = self.frame.size.width;
    self.gradient.frame = frame;
}

@end
