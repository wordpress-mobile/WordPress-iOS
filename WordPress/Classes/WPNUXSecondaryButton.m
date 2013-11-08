//
//  WPNUXSecondaryButton.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPNUXSecondaryButton.h"

@implementation WPNUXSecondaryButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureButton];
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

- (CGSize)intrinsicContentSize
{
    CGSize size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right;
    return size;
}

#pragma mark - Private Methods

- (void)configureButton
{
    UIImage *mainImage = [[UIImage imageNamed:@"btn-secondary"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    UIImage *tappedImage = [[UIImage imageNamed:@"btn-secondary-tap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0];
    self.titleLabel.minimumScaleFactor = 10.0/15.0;
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0, 15.0, 0, 15.0)];
    [self setBackgroundImage:mainImage forState:UIControlStateNormal];
    [self setBackgroundImage:tappedImage forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6] forState:UIControlStateHighlighted];
}


@end
