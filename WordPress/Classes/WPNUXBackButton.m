//
//  WPNUXBackButton.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPNUXBackButton.h"

@implementation WPNUXBackButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *mainImage = [[UIImage imageNamed:@"btn-back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 4)];
        UIImage *tappedImage = [[UIImage imageNamed:@"btn-back-tap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 4)];
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0];
        [self setTitleEdgeInsets:UIEdgeInsetsMake(-1.0, 12.0, 0, 10.0)];
        [self setTitleColor:[UIColor colorWithRed:22.0/255.0 green:160.0/255.0 blue:208.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithRed:17.0/255.0 green:134.0/255.0 blue:180.0/255.0 alpha:1.0] forState:UIControlStateHighlighted];
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
    frame.size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right;
    self.frame = frame;
}

@end
