//
//  QuickPhotoButton.m
//  WordPress
//
//  Created by Jorge Bernal on 4/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "QuickPhotoButton.h"


@implementation QuickPhotoButton

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect imageFrame = self.imageView.frame;
    imageFrame.origin.x = self.titleLabel.frame.origin.x - 10.0f - imageFrame.size.width;
    self.imageView.frame = imageFrame;
}

+ (QuickPhotoButton *)button {
    QuickPhotoButton *button = [QuickPhotoButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:[[UIImage imageNamed:@"quickPhotoButton.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
    [button setBackgroundImage:[[UIImage imageNamed:@"quickPhotoButtonHighlighted.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateHighlighted];
    return button;
}

@end
