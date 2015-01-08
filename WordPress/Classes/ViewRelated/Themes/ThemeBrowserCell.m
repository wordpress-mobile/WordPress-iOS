#import "ThemeBrowserCell.h"
#import "Theme.h"
#import "WPImageSource.h"
#import "WPStyleGuide.h"

@interface WPImageSource (Theme)

- (void)downloadThemeScreenshotForURL:(NSURL*)url themeId:(NSString*)themeId success:(void(^)(UIImage *image, NSString *themeId))success failure:(void (^)(NSError *error))failure;

@end

@interface ThemeBrowserCell ()

@property (nonatomic, weak) UIImageView *screenshot;
@property (nonatomic, weak) UILabel *title;
@property (nonatomic, weak) UIImageView *statusIcon;

@end

@implementation ThemeBrowserCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        BOOL isRetina = [[UIApplication sharedApplication] respondsToSelector:@selector(scale)];
        self.contentView.layer.borderWidth = isRetina ? 0.5f : 1.0f;
        self.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

        UIImageView *screenshot = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, IS_IPAD ? 225.0f : 204.0f)];
        _screenshot = screenshot;
        [_screenshot setContentMode:UIViewContentModeScaleAspectFit];
        [self.contentView addSubview:_screenshot];

        // theme-browse-current/theme-browse-premium 37x37
        UIImageView *statusIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 37.0f, 0, 37.0f, 37.0f)];
        _statusIcon = statusIcon;
        [self.contentView addSubview:_statusIcon];

        UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.screenshot.frame), self.contentView.bounds.size.width, 30.0f)];
        titleContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self.contentView addSubview:titleContainer];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, titleContainer.frame.size.width-12, titleContainer.frame.size.height)];
        _title = title;
        _title.backgroundColor = [UIColor clearColor];
        _title.textColor = [UIColor whiteColor];
        _title.font = [WPStyleGuide regularTextFont];
        [titleContainer addSubview:_title];
    }
    return self;
}

- (void)prepareForReuse
{
    self.screenshot.image = nil;
    self.statusIcon.image = nil;
}

- (void)setTheme:(Theme *)theme
{
    _theme = theme;
    self.title.text = _theme.name;

    if (_theme.isPremium) {
        _statusIcon.image = [UIImage imageNamed:@"theme-browse-premium"];
    }
    if (_theme.isCurrentTheme) {
        _statusIcon.image = [UIImage imageNamed:@"theme-browse-current"];
    }

    [[WPImageSource sharedSource] downloadThemeScreenshotForURL:[NSURL URLWithString:self.theme.screenshotUrl] themeId:_theme.themeId success:^(UIImage *image, NSString *themeId) {
        if ([themeId isEqualToString:_theme.themeId]) {
            _screenshot.image = image;
        }
    } failure:^(NSError *error) {
        DDLogWarn(@"Theme screenshot failed to download for theme: %@ error: %@", _theme.themeId, error);
    }];
}

@end

@implementation WPImageSource (Theme)

// Save the themeId to avoid the scenario where the cell has already been reused and the theme is now different
- (void)downloadThemeScreenshotForURL:(NSURL *)url
                              themeId:(NSString*)themeId
                              success:(void (^)(UIImage *image, NSString *themeId))success
                              failure:(void (^)(NSError *))failure
{
    [self downloadImageForURL:url withSuccess:^(UIImage *image) {
        success(image, themeId);
    } failure:failure];
}

@end
