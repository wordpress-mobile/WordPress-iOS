//
//  WPKeyboardToolbarButtonItem.m
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPKeyboardToolbarButtonItem.h"

@implementation WPKeyboardToolbarButtonItem
@synthesize actionTag, actionName;


+ (id)button {
    return [WPKeyboardToolbarButtonItem buttonWithType:UIButtonTypeCustom];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)setImageName:(NSString *)imageName {
    [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", imageName]] forState:UIControlStateNormal];
    self.imageView.contentMode = UIViewContentModeCenter;
}


- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        [self setBackgroundColor:[WPStyleGuide newKidOnTheBlockBlue]];
    } else {
        [self setBackgroundColor:[WPStyleGuide itsEverywhereGrey]];
    }
}


@end
