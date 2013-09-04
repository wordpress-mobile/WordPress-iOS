/*
 * MediaBrowserCell.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "MediaBrowserCell.h"
#import "Media.h"

@interface MediaBrowserCell ()

@property (nonatomic, weak) UIImageView *thumbnail;
@property (nonatomic, weak) UILabel *title;
@property (nonatomic, weak) UIImageView *checkboxView;

@end

@implementation MediaBrowserCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        BOOL isRetina = [[UIApplication sharedApplication] respondsToSelector:@selector(scale)];
        self.contentView.layer.borderWidth = isRetina ? 0.5f : 1.0f;
        self.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        UIImageView *thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, 145)];
        _thumbnail = thumbnail;
        [_thumbnail setContentMode:UIViewContentModeScaleAspectFit];
        [self.contentView addSubview:_thumbnail];
        
        UIImageView *checkboxView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 37.0f, 0, 37.0f, 37.0f)];
        _checkboxView = checkboxView;
        [self.contentView addSubview:_checkboxView];
        
        UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.thumbnail.frame), self.contentView.bounds.size.width, 20.0f)];
        titleContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self.contentView addSubview:titleContainer];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, titleContainer.frame.size.width-6, titleContainer.frame.size.height)];
        _title = title;
        _title.backgroundColor = [UIColor clearColor];
        _title.textColor = [UIColor whiteColor];
        _title.font = [WPStyleGuide regularTextFont];
        [titleContainer addSubview:_title];
    }
    return self;
}

- (void)prepareForReuse {
    self.thumbnail.image = nil;
}

- (void)setMedia:(Media *)media {
    _media = media;
    self.title.text = _media.title;
    
    _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
}

@end
