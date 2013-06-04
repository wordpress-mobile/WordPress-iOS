//
//  WPNUXMainButton.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPNUXMainButton.h"

@implementation WPNUXMainButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *mainImage = [[UIImage imageNamed:@"btn-main"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        UIImage *inactiveImage = [[UIImage imageNamed:@"btn-main-inactive"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        UIImage *tappedImage = [[UIImage imageNamed:@"btn-main-tap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        [self setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
        [self setBackgroundImage:mainImage forState:UIControlStateNormal];
        [self setBackgroundImage:inactiveImage forState:UIControlStateDisabled];
        [self setBackgroundImage:tappedImage forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateDisabled];
        [self setTitleColor:[UIColor colorWithRed:9.0/255.0 green:134.0/255.0 blue:181.0/255.0 alpha:0.4] forState:UIControlStateHighlighted];
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:20.0];
    
    }
    return self;
}

@end
