//
//  WPNUXPrimaryButton.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPNUXPrimaryButton.h"

@implementation WPNUXPrimaryButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *mainImage = [[UIImage imageNamed:@"btn-primary"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        UIImage *tappedImage = [[UIImage imageNamed:@"btn-primary-tap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        self.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0, 15.0, 0, 15.0)];
        [self setBackgroundImage:mainImage forState:UIControlStateNormal];
        [self setBackgroundImage:tappedImage forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9] forState:UIControlStateNormal];
        [self setTitleShadowColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithRed:25.0/255.0 green:135.0/255.0 blue:179.0/255.0 alpha:1.0] forState:UIControlStateHighlighted];
        [self setTitleShadowColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1] forState:UIControlStateHighlighted];
        self.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    }
    return self;
}

- (void)sizeToFit
{
    [super sizeToFit];
    
    // Adjust frame to account for the edge insets
    CGRect frame = self.frame;
    frame.size.width += 30;
    self.frame = frame;
}

@end
