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

- (id)init {
    self = [super init];
    if (self) {
        WPFLogMethod();
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        WPFLogMethod();
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        WPFLogMethod();

//        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [self setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        self.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		
        if (IS_IPAD) {
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtoniPad"] stretchableImageWithLeftCapWidth:10.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtoniPadHighlighted"] stretchableImageWithLeftCapWidth:10.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        } else {
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButton"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)setImageName:(NSString *)imageName {
    if (IS_IPAD) {
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@iPad", imageName]] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@iPadHighlighted", imageName]] forState:UIControlStateHighlighted];
    } else {
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", imageName]] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@Highlighted", imageName]] forState:UIControlStateHighlighted];        
    }
}

@end
