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

- (void)dealloc
{
    self.actionTag = nil;
    self.actionName = nil;
    [super dealloc];
}

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

        [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButton"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
		[self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];

    }
    return self;
}

@end
