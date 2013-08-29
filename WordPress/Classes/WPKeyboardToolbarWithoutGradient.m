//
//  WPKeyboardToolbarWithoutGradient.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPKeyboardToolbarWithoutGradient.h"

@implementation WPKeyboardToolbarWithoutGradient

- (void)setupView
{
    if (IS_IPAD) {
        self.backgroundColor = [UIColor UIColorFromHex:0xcfd2d6];
    } else {
        self.backgroundColor = [UIColor UIColorFromHex:0xd9dbdf];        
    }
    [super setupView];
}

@end
