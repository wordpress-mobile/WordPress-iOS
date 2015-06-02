#import "ThemeDetailsViewController.h"
#import "Theme.h"
#import "WPImageSource.h"
#import "WPWebViewController.h"
#import "WPAccount.h"
#import "WPStyleGuide.h"
#import "Blog.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "AccountService.h"

@interface ThemeDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIView *themeControlsView;
@property (weak, nonatomic) IBOutlet UIView *themeControlsContainerView;
@property (weak, nonatomic) IBOutlet UILabel *themeName;
@property (weak, nonatomic) IBOutlet UIImageView *screenshot;
@property (weak, nonatomic) IBOutlet UIButton *livePreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *activateButton;
@property (nonatomic, strong) Theme *theme;
@property (nonatomic, weak) UILabel *tagCloud;
@property (nonatomic, weak) UILabel *currentTheme;
@property (nonatomic, weak) UILabel *premiumTheme;
@property (weak, nonatomic) UIView *infoView;

@end

@implementation ThemeDetailsViewController

- (id)initWithTheme:(Theme *)theme
{
    self = [super init];
    if (self) {
        _theme = theme;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Details", @"Theme details. Final string TBD");

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.themeControlsContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.themeControlsContainerView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    [self.view addSubview:self.themeControlsContainerView];

    self.themeName.text = self.theme.name;
    self.themeName.font = [WPStyleGuide largePostTitleFont];
    self.themeName.textColor = [WPStyleGuide littleEddieGrey];
    self.themeName.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.themeName.frame = (CGRect) {
        .origin =  CGPointMake((IS_IPAD ? 0 : 10.0f), self.themeName.frame.origin.y),
        .size = self.themeName.frame.size
    };

    self.livePreviewButton.titleLabel.font = [WPStyleGuide regularTextFont];
    self.activateButton.titleLabel.font = self.livePreviewButton.titleLabel.font;
    self.livePreviewButton.titleLabel.text = NSLocalizedString(@"Live Preview", nil);
    self.activateButton.titleLabel.text = NSLocalizedString(@"Activate", nil);
    [self.livePreviewButton setBackgroundColor:[WPStyleGuide whisperGrey]];
    [self.activateButton setBackgroundColor:[WPStyleGuide wordPressBlue]];
    self.livePreviewButton.layer.cornerRadius = 3.0f;
    self.activateButton.layer.cornerRadius = 3.0f;
    self.livePreviewButton.exclusiveTouch = YES;
    self.activateButton.exclusiveTouch = YES;

    if ([self.theme isCurrentTheme]) {
        [self showAsCurrentTheme];
    }

    if (self.theme.isPremium) {
        [self showAsPremiumTheme];
    }

    [self setupInfoView];

    ((UIScrollView *)self.view).contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(_infoView.frame));

    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:self.theme.screenshotUrl] withSuccess:^(UIImage *image) {
        self.screenshot.image = image;
    } failure:nil];
}

- (void)viewDidLayoutSubviews
{
    self.livePreviewButton.frame = (CGRect) {
        .origin = CGPointMake(_livePreviewButton.frame.origin.x, CGRectGetMaxY(_screenshot.frame) + 7.0f),
        .size = _livePreviewButton.frame.size
    };
    self.activateButton.frame = (CGRect) {
        .origin = CGPointMake(_activateButton.frame.origin.x, _livePreviewButton.frame.origin.y),
        .size = _activateButton.frame.size
    };
    self.themeControlsContainerView.frame = (CGRect) {
        .origin = _themeControlsContainerView.frame.origin,
        .size = CGSizeMake(_themeControlsContainerView.frame.size.width, CGRectGetMaxY(_livePreviewButton.frame) + 10.0f)
    };
    self.infoView.frame = (CGRect) {
        .origin = CGPointMake(_infoView.frame.origin.x, CGRectGetMaxY(_themeControlsContainerView.frame) + 10),
        .size = _infoView.frame.size
    };

    _themeControlsView.center = CGPointMake(self.view.center.x, _themeControlsView.center.y);
    _infoView.center = CGPointMake(_themeControlsView.center.x, _infoView.center.y);

    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(_infoView.frame));
}

- (void)setupInfoView
{
    UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(IS_IPAD ? 0 : 10, CGRectGetMaxY(_themeControlsView.frame), _themeControlsView.frame.size.width - (IS_IPAD ? 0 : 20), 0)];
    _infoView = infoView;

    UILabel *detailsTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, _infoView.frame.size.width, 0)];
    detailsTitle.text = NSLocalizedString(@"Details", @"Title for theme details");
    detailsTitle.font = [WPStyleGuide postTitleFont];
    detailsTitle.textColor = [WPStyleGuide littleEddieGrey];
    detailsTitle.opaque = YES;
    detailsTitle.backgroundColor = [UIColor whiteColor];
    [detailsTitle sizeToFit];
    [_infoView addSubview:detailsTitle];

    UILabel *detailsText = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(detailsTitle.frame) + 3.0f, _infoView.frame.size.width, 0)];
    detailsText.text = self.theme.details;
    detailsText.numberOfLines = 0;
    detailsText.font = [WPStyleGuide regularTextFont];
    detailsText.textColor = [WPStyleGuide whisperGrey];
    detailsText.opaque = YES;
    detailsText.backgroundColor = [UIColor whiteColor];
    [detailsText sizeToFit];
    [_infoView addSubview:detailsText];

    UILabel *tagsTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(detailsText.frame) + 20.0f, _infoView.frame.size.width, 0)];
    tagsTitle.text = NSLocalizedString(@"Tags", @"Title for theme tags");
    tagsTitle.font = detailsTitle.font;
    tagsTitle.opaque = YES;
    tagsTitle.backgroundColor = [UIColor whiteColor];
    [tagsTitle sizeToFit];
    [_infoView addSubview:tagsTitle];

    UILabel *tags = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(tagsTitle.frame) + 3.0f, _infoView.frame.size.width, 0)];
    tags.text = [self formattedTags];
    tags.numberOfLines = 0;
    tags.font = detailsText.font;
    tags.opaque = YES;
    tags.backgroundColor = [UIColor whiteColor];
    tags.textColor = detailsText.textColor;
    [tags sizeToFit];
    [_infoView addSubview:tags];

    _infoView.frame = (CGRect) {
        .origin = _infoView.frame.origin,
        .size = CGSizeMake(_infoView.frame.size.width, CGRectGetMaxY(tags.frame) + 10)
    };
    [self.view addSubview:_infoView];
}

- (NSString *)formattedTags
{
    NSMutableArray *formattedTags = [NSMutableArray array];
    [self.theme.tags enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        obj = [obj stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        obj = [obj capitalizedString];
        [formattedTags addObject:obj];
    }];
    return [formattedTags componentsJoinedByString:@", "];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    [self.screenshot removeFromSuperview];
    self.screenshot.image = nil;
}

- (void)showViewSite
{
    // Remove activate theme button, and live preview becomes the 'View Site' button
    [self.livePreviewButton setTitle:NSLocalizedString(@"View Site", @"") forState:UIControlStateNormal];
    self.livePreviewButton.center = CGPointMake(self.screenshot.center.x, self.livePreviewButton.center.y);
    self.activateButton.alpha = 0;
}

- (void)showAsCurrentTheme
{
    UILabel *currentTheme = [[UILabel alloc] init];
    _currentTheme = currentTheme;
    _currentTheme.text = NSLocalizedString(@"Current Theme", @"Denote a theme as the current");
    _currentTheme.font = [WPStyleGuide regularTextFont];
    _currentTheme.textColor = [WPStyleGuide whisperGrey];
    _currentTheme.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    _currentTheme.opaque = YES;
    [_currentTheme sizeToFit];

    _currentTheme.frame = (CGRect) {
        .origin = CGPointMake(_themeName.frame.origin.x, CGRectGetMaxY(_themeName.frame)),
        .size = _currentTheme.frame.size
    };
    [self.themeControlsView addSubview:_currentTheme];

    self.screenshot.frame = (CGRect) {
        .origin = CGPointMake(_screenshot.frame.origin.x, CGRectGetMaxY(_currentTheme.frame) + 7.0f),
        .size = _screenshot.frame.size
    };

    [self showViewSite];
}

- (void)showAsPremiumTheme
{
    UIImageView *premiumIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"theme-browse-premium"]];
    premiumIcon.frame = (CGRect) {
        .origin = CGPointMake(_screenshot.frame.size.width - premiumIcon.frame.size.width, 0),
        .size = premiumIcon.frame.size
    };
    [_screenshot addSubview:premiumIcon];
}

- (IBAction)livePreviewPressed:(id)sender
{
    // Live preview URL yields the same result as 'view current site'.
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    NSURL *targetURL = [NSURL URLWithString:self.theme.previewUrl];
    WPWebViewController *livePreviewController = [WPWebViewController webViewControllerWithURL:targetURL];
    livePreviewController.authToken = defaultAccount.authToken;
    livePreviewController.username = defaultAccount.username;
    livePreviewController.password = defaultAccount.password;
    livePreviewController.wpLoginURL = [NSURL URLWithString:self.theme.blog.loginUrl];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:livePreviewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)activatePressed:(id)sender
{
    __block UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loading startAnimating];
    loading.center = CGPointMake(self.activateButton.bounds.size.width/2, self.activateButton.bounds.size.height/2);
    [self.activateButton setTitle:@"" forState:UIControlStateNormal];
    [self.activateButton addSubview:loading];

    [self.theme activateThemeWithSuccess:^{
        [WPAnalytics track:WPAnalyticsStatThemesChangedTheme];
        [loading removeFromSuperview];
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self showViewSite];
        } completion:nil];
    } failure:^(NSError *error) {
        [loading removeFromSuperview];
        [self.activateButton setTitle:NSLocalizedString(@"Activate", nil) forState:UIControlStateNormal];
        [WPError showNetworkingAlertWithError:error];
    }];
}

@end
