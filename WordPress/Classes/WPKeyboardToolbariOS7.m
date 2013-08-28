//
//  WPKeyboardToolbariOS7.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPKeyboardToolbariOS7.h"

@implementation WPKeyboardToolbariOS7

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
