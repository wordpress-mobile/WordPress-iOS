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
        self.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        UIImageView *screenshot = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, 112.0f)];
        self.screenshot = screenshot;
        [self.screenshot setContentMode:UIViewContentModeScaleAspectFit];
        [self.contentView addSubview:self.screenshot];
        
        UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.screenshot.frame), self.contentView.bounds.size.width, 15.0f)];
        titleContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self.contentView addSubview:titleContainer];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, titleContainer.frame.size.width-6, titleContainer.frame.size.height)];
        self.title = title;
        self.title.backgroundColor = [UIColor clearColor];
        self.title.textColor = [UIColor whiteColor];
        self.title.font = [UIFont fontWithName:@"OpenSans" size:9.0f];
        [titleContainer addSubview:title];
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
