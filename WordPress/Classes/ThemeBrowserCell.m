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
#import "WPImageSource.h"

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
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, self.contentView.bounds.size.height-24.0f, self.contentView.bounds.size.width, 24.0f)];
        self.title = title;
        self.title.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        self.title.opaque = false;
        self.title.textColor = [UIColor whiteColor];
        self.title.font = [UIFont systemFontOfSize:14.0f];
        [self.contentView addSubview:self.title];
    }
    return self;
}

- (void)setTheme:(Theme *)theme {
    _theme = theme;
    self.title.text = _theme.name;
    
    self.screenshot.image = nil;
    
    // TODO possible to make this cancellable if we've scrolled past or is it worth it (ends up in the cache anyways)
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:self.theme.screenshotUrl] withSuccess:^(UIImage *image) {
        self.screenshot.image = image;
    } failure:^(NSError *error) {
        
    }];
}

@end
