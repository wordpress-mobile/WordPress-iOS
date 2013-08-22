/*
 * ThemeSearchFilterHeaderView.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeSearchFilterHeaderView.h"
#import "ThemeBrowserViewController.h"

@implementation ThemeSearchFilterHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *search = [[UILabel alloc] initWithFrame:frame];
        search.text = @"Search & Filter";
        [self addSubview:search];
    }
    return self;
}

@end
