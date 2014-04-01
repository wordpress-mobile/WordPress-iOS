#import "MediaBrowserCell.h"
#import "Media.h"
#import "WPImageSource.h"
#import "UIImage+Resize.h"
#import "WPAccount.h"

@interface WPImageSource (Media)

- (void)downloadThumbnailForMedia:(Media*)media success:(void (^)(NSNumber *mediaId))success failure:(void (^)(NSError *error))failure;

@end

@interface MediaBrowserCell ()

@property (nonatomic, weak) UIImageView *thumbnail;
@property (nonatomic, weak) UILabel *title;
@property (nonatomic, weak) UIButton *checkbox;
@property (nonatomic, weak) UIView *uploadStatusOverlay;

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
        [_thumbnail setContentMode:UIViewContentModeCenter];
        [self.contentView addSubview:_thumbnail];
        
        // With enlarged touch area
        UIButton *checkbox = [[UIButton alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 37.0f, 0, 37.0f, 37.0f)];
        _checkbox = checkbox;
        [_checkbox addTarget:self action:@selector(checkboxPressed) forControlEvents:UIControlEventTouchUpInside];
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_empty"] forState:UIControlStateNormal];
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_filled"] forState:UIControlStateHighlighted];
        [self.contentView addSubview:_checkbox];
        
        UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.thumbnail.frame), self.contentView.bounds.size.width, 25.0f)];
        titleContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self.contentView addSubview:titleContainer];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, titleContainer.frame.size.width-10, titleContainer.frame.size.height)];
        _title = title;
        _title.backgroundColor = [UIColor clearColor]; 
        _title.textColor = [UIColor whiteColor];
        _title.lineBreakMode = NSLineBreakByTruncatingTail;
        _title.font = [WPStyleGuide subtitleFont];
        [titleContainer addSubview:_title];
    }
    return self;
}

- (void)dealloc {
    [self removeUploadStatusObservers];
}

- (void)setHideCheckbox:(BOOL)hideCheckbox {
    _checkbox.hidden = hideCheckbox;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    
    if (_isSelected) {
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_filled"] forState:UIControlStateNormal];
    } else {
        [_checkbox setImage:[UIImage imageNamed:@"media_checkbox_empty"] forState:UIControlStateNormal];
    }
}

- (void)checkboxPressed {
    self.isSelected = !_isSelected;
    if (_isSelected) {
        [_delegate mediaCellSelected:self.media];
    } else {
        [_delegate mediaCellDeselected:self.media];
    }
}

- (void)prepareForReuse {
    self.thumbnail.image = nil;
    self.isSelected = NO;
    if (!_thumbnail.image) {
        _thumbnail.contentMode = UIViewContentModeCenter;
    }
    [_uploadStatusOverlay removeFromSuperview];
    
    [self removeUploadStatusObservers];
}

#pragma mark - KVO

- (void)addUploadStatusObservers {
    [self updateUploadStatusOverlay];
    [_media addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:0];
    [_media addObserver:self forKeyPath:@"remoteStatus" options:NSKeyValueObservingOptionNew context:0];
}

- (void)removeUploadStatusObservers {
    [_media removeObserver:self forKeyPath:@"progress"];
    [_media removeObserver:self forKeyPath:@"remoteStatus"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    _title.text = [self titleForMedia];
    
    if ([keyPath isEqualToString:@"remoteStatus"]) {
        [self updateUploadStatusOverlay];
    }
}

- (void)setMedia:(Media *)media {
    _media = media;
    
    _title.text = [self titleForMedia];
    
    _thumbnail.image = [UIImage imageNamed:[@"media_" stringByAppendingString:_media.mediaTypeString]];

    if (_media.thumbnail.length > 0) {
        @autoreleasepool {
            _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
        }
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    [self addUploadStatusObservers];
}

- (void)loadThumbnail {
    // TODO: Video thumbnails are not available from the API.
    if (_media.mediaType == MediaTypeImage && _media.remoteURL && _media.thumbnail.length == 0) {
        [[WPImageSource sharedSource] downloadThumbnailForMedia:_media success:^(NSNumber *mediaId){
            if ([mediaId isEqualToNumber:_media.mediaID]) {
                _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
                _thumbnail.image = [UIImage imageWithData:_media.thumbnail];
            }
        } failure:^(NSError *error) {
            DDLogWarn(@"Failed to download thumbnail for media %@: %@", _media.remoteURL, error);
        }];
    }
}

- (void)updateUploadStatusOverlay {
    [_uploadStatusOverlay removeFromSuperview];
    
    if (_media.remoteStatus == MediaRemoteStatusPushing || _media.remoteStatus == MediaRemoteStatusFailed) {
        UIView *statusOverlay = [[UIView alloc] initWithFrame:_thumbnail.bounds];
        _uploadStatusOverlay = statusOverlay;
        _uploadStatusOverlay.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0 alpha:0.6];
        [_thumbnail addSubview:_uploadStatusOverlay];
        
        UIImageView *arrows = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uploading_spin_blue"]];
        arrows.center = CGPointMake(_uploadStatusOverlay.center.x, _uploadStatusOverlay.center.y);
        [_uploadStatusOverlay addSubview:arrows];
        
        UILabel *instruction = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(arrows.frame), _uploadStatusOverlay.frame.size.width, 30)];
        instruction.backgroundColor = [UIColor clearColor];
        instruction.font = [WPStyleGuide subtitleFont];
        instruction.textColor = [UIColor whiteColor];
        instruction.textAlignment = NSTextAlignmentCenter;
        [_uploadStatusOverlay addSubview:instruction];
    
        if (_media.remoteStatus == MediaRemoteStatusFailed) {
            arrows.image = [UIImage imageNamed:@"uploading_spin_red"];
            instruction.text = [NSLocalizedString(@"Tap to retry", @"If a media upload fails, instruction to retry displayed") uppercaseString];
        } else {
            CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
            spin.toValue = [NSNumber numberWithFloat:(M_PI * 2)];
            spin.duration = 1.5f;
            spin.cumulative = YES;
            spin.repeatCount = MAXFLOAT;
            [arrows.layer addAnimation:spin forKey:@"spin"];
            instruction.text = [NSLocalizedString(@"Tap to cancel", @"During media upload, 'tap to cancel' instruction") uppercaseString];
        }
    }
}

- (NSString *)titleForMedia {
    if (_media.remoteStatus == MediaRemoteStatusPushing) {
        NSString *title = NSLocalizedString(@"Processing...", @"Uploading message displayed when an image has finished uploading.");
        if (_media.progress < 1.0f) {
            title = [NSString stringWithFormat:NSLocalizedString(@"%.1f%%.", @"Uploading message with percentage displayed when an image is uploading."), _media.progress * 100.0];
        }
        return title;
    } else if (_media.remoteStatus == MediaRemoteStatusProcessing) {
        return NSLocalizedString(@"Preparing...", @"Uploading message when an image is about to be uploaded.");
    
    } else if (_media.remoteStatus == MediaRemoteStatusFailed) {
        return NSLocalizedString(@"Upload failed.", @"Uploading message when a media upload has failed.");
    
    } else {
        if (_media.title.length > 0) {
            return _media.title;
        }

        NSString *filesizeString = nil;
        if ([_media.filesize floatValue] > 1024) {
            filesizeString = [NSString stringWithFormat:@"%.2f MB", ([_media.filesize floatValue]/1024)];
        } else {
            filesizeString = [NSString stringWithFormat:@"%.2f KB", [_media.filesize floatValue]];
        }
        
        if (_media.mediaType == MediaTypeImage) {
            return [NSString stringWithFormat:@"%dx%d %@", [_media.width intValue], [_media.height intValue], filesizeString];
        } else if (_media.mediaType == MediaTypeVideo) {
            NSNumber *valueForDisplay = [NSNumber numberWithDouble:[_media.length doubleValue]];
            NSNumber *days = [NSNumber numberWithDouble:
                              ([valueForDisplay doubleValue] / 86400)];
            NSNumber *hours = [NSNumber numberWithDouble:
                               (([valueForDisplay doubleValue] / 3600) -
                                ([days intValue] * 24))];
            NSNumber *minutes = [NSNumber numberWithDouble:
                                 (([valueForDisplay doubleValue] / 60) -
                                  ([days intValue] * 24 * 60) -
                                  ([hours intValue] * 60))];
            NSNumber *seconds = [NSNumber numberWithInt:([valueForDisplay intValue] % 60)];
            return [NSString stringWithFormat:
                           @"%02d:%02d:%02d %@",
                           [hours intValue],
                           [minutes intValue],
                           [seconds intValue],
                           filesizeString];
        } else {
            return NSLocalizedString(@"Untitled", @"");
        }
    }
}

@end

@implementation WPImageSource (Media)

- (void)downloadThumbnailForMedia:(Media *)media success:(void (^)(NSNumber *mediaId))success failure:(void (^)(NSError *))failure {
    void (^thumbDownloadedSuccess)(UIImage *) = ^(UIImage *image) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *thumbnail = image;
            if (thumbnail.size.width > 145 || thumbnail.size.height > 145) {
                thumbnail = [image thumbnailImage:145 transparentBorder:0 cornerRadius:0 interpolationQuality:0.9];
            }
            __block NSData *thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.90);
            dispatch_async(dispatch_get_main_queue(), ^{
                media.thumbnail = thumbnailData;
                success(media.mediaID);
            });
        });
    };
    
    NSString *thumbnailUrl = media.remoteURL;
    if (media.blog.isWPcom) {
        thumbnailUrl = [thumbnailUrl stringByAppendingString:@"?w=145"];
    }
    
    if (media.blog.isPrivate) {
        [self downloadImageForURL:[NSURL URLWithString:thumbnailUrl] authToken:[[[WPAccount defaultWordPressComAccount] restApi] authToken] withSuccess:thumbDownloadedSuccess failure:failure];
    } else {
        [self downloadImageForURL:[NSURL URLWithString:thumbnailUrl] withSuccess:thumbDownloadedSuccess failure:failure];
    }
}

@end
