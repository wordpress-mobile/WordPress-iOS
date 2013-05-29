//
//  WPNUXBackButton.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPNUXBackButton.h"

@implementation WPNUXBackButton

// There's some extra space in the btn-back and btn-back-tap images to improve the
// tap area of this image and in order for sizeToFit to work correctly we have to take
// this extra space into account.
CGFloat const WPNUXBackButtonExtraHorizontalWidthForSpace = 30;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *mainImage = [[UIImage imageNamed:@"btn-back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 21, 0, 18)];
        UIImage *tappedImage = [[UIImage imageNamed:@"btn-back-tap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 21, 0, 18)];
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0];
        self.titleLabel.shadowOffset = CGSizeMake(0, -1);
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 6.0, 0, 10.0)];
        [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] forState:UIControlStateHighlighted];
        [self setTitleShadowColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1] forState:UIControlStateNormal];
        [self setTitleShadowColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.05] forState:UIControlStateNormal];
        [self setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [self setBackgroundImage:mainImage forState:UIControlStateNormal];
        [self setBackgroundImage:tappedImage forState:UIControlStateHighlighted];
    }
    return self;
}

- (void)sizeToFit
{
    [super sizeToFit];
    
    // Adjust frame to account for the edge insets
    CGRect frame = self.frame;
    frame.size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right + WPNUXBackButtonExtraHorizontalWidthForSpace;
    self.frame = frame;
}

@end
