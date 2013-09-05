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
#import "WPImageSource.h"

@interface WPImageSource (Media)

- (void)downloadThumbnailForMedia:(Media*)media success:(void (^)(NSNumber *mediaId))success failure:(void (^)(NSError *error))failure;

@end

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
        
        UIImageView *thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, IS_IPAD ? 200 : 145)];
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

- (void)updateForSelection
{
    [self bringSubviewToFront:_checkboxView];
    if (_isSelected) {
        [_checkboxView setBackgroundColor:[UIColor redColor]];
//        _checkboxView setImage:<#(UIImage *)#>
    } else {
        [_checkboxView setBackgroundColor:[UIColor clearColor]];
//    _checkboxView setImage:<#(UIImage *)#>
    }
}

- (void)prepareForReuse {
    self.thumbnail.image = nil;
}

- (void)setMedia:(Media *)media {
    _media = media;
    self.title.text = _media.title;
    
    if (_media.thumbnail.length > 0) {
        _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
    } else {
        [[WPImageSource sharedSource] downloadThumbnailForMedia:_media success:^(NSNumber *mediaId){
            if ([mediaId isEqualToNumber:_media.mediaID]) {
                _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
            }
        } failure:^(NSError *error) {
            WPFLog(@"Failed to download thumbnail for media %@: %@", _media.remoteURL, error);
        }];
    }
}

@end

@implementation WPImageSource (Media)

- (void)downloadThumbnailForMedia:(Media*)media success:(void (^)(NSNumber *mediaId))success failure:(void (^)(NSError *))failure {
    NSURL *thumbnailUrl = [NSURL URLWithString:[media.remoteURL stringByAppendingString:@"?w=145"]];
    [self downloadImageForURL:thumbnailUrl withSuccess:^(UIImage *image) {
        media.thumbnail = UIImageJPEGRepresentation(image, 0.90);
        success(media.mediaID);
    } failure:failure];
}

@end
