/*
 * ThemeBrowserCell.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeBrowserCell.h"
#import "Theme.h"

@interface ThemeBrowserCell ()

@property (nonatomic, weak) UIImageView *screenshot;
@property (nonatomic, weak) UILabel *title;

@end

@implementation ThemeBrowserCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.borderWidth = 0.5f;
        self.contentView.layer.borderColor = [[UIColor grayColor] CGColor];
        
        UIImageView *screenshot = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        self.screenshot = screenshot;
        self.screenshot.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        self.screenshot.opaque = true;
        [self.contentView addSubview:self.screenshot];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, self.contentView.bounds.size.height-40.0f, self.contentView.bounds.size.width, 40.0f)];
        self.title = title;
        self.title.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        self.title.opaque = false;
        [self.contentView addSubview:self.title];
    }
    return self;
}

- (void)setTheme:(Theme *)theme {
    _theme = theme;
    self.title.text = _theme.name;
}

@end
