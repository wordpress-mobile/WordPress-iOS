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


- (void)configureButton
{
    [self setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateDisabled];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateHighlighted];
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    [self setColor:[UIColor colorWithRed:0/255.0f green:116/255.0f blue:162/255.0f alpha:1.0f]];
}

- (void)setColor:(UIColor *)color {
    
    CGRect fillRect = CGRectMake(0, 0, 11.0, 40.0);
    UIEdgeInsets capInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    UIImage *mainImage;
    
    UIGraphicsBeginImageContextWithOptions(fillRect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:3.0].CGPath);
    CGContextClip(context);
    CGContextFillRect(context, fillRect);
    mainImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:[mainImage resizableImageWithCapInsets:capInsets] forState:UIControlStateNormal];
}

@end
