/*
 * ThemeDetailsViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeDetailsViewController.h"
#import "Theme.h"
#import "WPImageSource.h"
#import "WPWebViewController.h"
#import "WPAccount.h"
#import "WPStyleGuide.h"
#import "Blog.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"

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

- (id)initWithTheme:(Theme *)theme {
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
    [self.view addSubview:self.themeControlsContainerView];
    
    self.themeName.text = self.theme.name;
    self.themeName.font = [WPStyleGuide largePostTitleFont];
    [self.themeName sizeToFit];
    
    if ([self.theme isCurrentTheme]) {
        [self showAsCurrentTheme];
    } else {
        self.activateButton.layer.cornerRadius = 4.0f;
        self.activateButton.titleLabel.font = [WPStyleGuide regularTextFont];
    }
    
    if (self.theme.isPremium) {
        [self showAsPremiumTheme];
    }
    
    self.livePreviewButton.titleLabel.font = [WPStyleGuide regularTextFont];
    self.livePreviewButton.layer.cornerRadius = 4.0f;
    
    // Should just be text and no background if iOS7
    [self.livePreviewButton setBackgroundColor:[WPStyleGuide baseDarkerBlue]];
    
    [self setupInfoView];
    
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(_infoView.frame));
    
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:self.theme.screenshotUrl] withSuccess:^(UIImage *image) {
        self.screenshot.image = image;
    } failure:nil];
}

- (void)viewDidLayoutSubviews {
    self.livePreviewButton.frame = (CGRect) {
        .origin = CGPointMake(_livePreviewButton.frame.origin.x, CGRectGetMaxY(_screenshot.frame) + 7),
        .size = _livePreviewButton.frame.size
    };
    self.activateButton.frame = (CGRect) {
        .origin = CGPointMake(_activateButton.frame.origin.x, _livePreviewButton.frame.origin.y),
        .size = _activateButton.frame.size
    };
    self.themeControlsContainerView.frame = (CGRect) {
        .origin = _themeControlsContainerView.frame.origin,
        .size = CGSizeMake(_themeControlsContainerView.frame.size.width, CGRectGetMaxY(_livePreviewButton.frame) + 10)
    };
    self.infoView.frame = (CGRect) {
        .origin = CGPointMake(_infoView.frame.origin.x, CGRectGetMaxY(_themeControlsContainerView.frame) + 10),
        .size = _infoView.frame.size
    };
    
    _themeControlsView.center = CGPointMake(self.view.center.x, _themeControlsView.center.y);
    _infoView.center = CGPointMake(_themeControlsView.center.x, _infoView.center.y);
    
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(_infoView.frame));
}

- (void)setupInfoView {
    UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(IS_IPAD ? 0 : 7, CGRectGetMaxY(_themeControlsView.frame), _themeControlsView.frame.size.width - (IS_IPAD ? 0 : 7), 0)];
    _infoView = infoView;
    
    UILabel *detailsTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, _infoView.frame.size.width, 0)];
    detailsTitle.text = NSLocalizedString(@"Details", @"Title for theme details");
    detailsTitle.font = [WPStyleGuide postTitleFont];
    [detailsTitle sizeToFit];
    [_infoView addSubview:detailsTitle];
    
    UILabel *detailsText = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(detailsTitle.frame), _infoView.frame.size.width, 0)];
    detailsText.text = self.theme.details;
    detailsText.numberOfLines = 0;
    detailsText.font = [WPStyleGuide regularTextFont];
    [detailsText sizeToFit];
    [_infoView addSubview:detailsText];
    
    UILabel *tagsTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(detailsText.frame) + 20, _infoView.frame.size.width, 0)];
    tagsTitle.text = NSLocalizedString(@"Tags", @"Title for theme tags");
    tagsTitle.font = detailsTitle.font;
    [tagsTitle sizeToFit];
    [_infoView addSubview:tagsTitle];
    
    UILabel *tags = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(tagsTitle.frame), _infoView.frame.size.width, 0)];
    tags.text = [self formattedTags];
    tags.numberOfLines = 0;
    tags.font = [WPStyleGuide subtitleFont];
    [tags sizeToFit];
    [_infoView addSubview:tags];
    
    _infoView.frame = (CGRect) {
        .origin = _infoView.frame.origin,
        .size = CGSizeMake(_infoView.frame.size.width, CGRectGetMaxY(tags.frame) + 10)
    };
    [self.view addSubview:_infoView];
}

- (NSString *)formattedTags {
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

- (UILabel*)themeStatusLabelWithText:(NSString*)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [WPStyleGuide regularTextFont];
    label.textColor = [WPStyleGuide littleEddieGrey];
    [label sizeToFit];
    return label;
}

- (void)showViewSite {
    // Remove activate theme button, and live preview becomes the 'View Site' button
    [self.livePreviewButton setTitle:NSLocalizedString(@"View Site", @"") forState:UIControlStateNormal];
    CGRect f = self.livePreviewButton.frame;
    f.size.width = CGRectGetMaxX(self.activateButton.frame) - self.livePreviewButton.frame.origin.x;
    self.livePreviewButton.frame = f;
    self.activateButton.alpha = 0;
}

- (void)showAsCurrentTheme {
    UILabel *currentTheme = [self themeStatusLabelWithText:NSLocalizedString(@"Current Theme", @"Denote a theme as the current")];
    _currentTheme = currentTheme;
    _currentTheme.backgroundColor = [UIColor clearColor]; // for iOS 6
    [_currentTheme sizeToFit];
    _currentTheme.frame = (CGRect) {
        .origin = CGPointMake(_themeName.frame.origin.x, CGRectGetMaxY(_themeName.frame)),
        .size = _currentTheme.frame.size
    };
    [self.themeControlsView addSubview:_currentTheme];
    
    self.screenshot.frame = (CGRect) {
        .origin = CGPointMake(_screenshot.frame.origin.x, CGRectGetMaxY(_currentTheme.frame) + 7),
        .size = _screenshot.frame.size
    };
    
    [self showViewSite];
    
    [self.view setNeedsLayout];
}

- (void)showAsPremiumTheme {
    UIImageView *premiumIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"theme-browse-premium"]];
    premiumIcon.frame = (CGRect) {
        .origin = CGPointMake(_screenshot.frame.size.width - premiumIcon.frame.size.width, 0),
        .size = premiumIcon.frame.size
    };
    [_screenshot addSubview:premiumIcon];
}

- (IBAction)livePreviewPressed:(id)sender {
    // Live preview URL yields the same result as 'view current site'.
    WPWebViewController *livePreviewController = [[WPWebViewController alloc] init];
    livePreviewController.username = [WPAccount defaultWordPressComAccount].username;
    livePreviewController.password = [WPAccount defaultWordPressComAccount].password;
    [livePreviewController setWpLoginURL:[NSURL URLWithString:self.theme.blog.loginUrl]];
    livePreviewController.url = [NSURL URLWithString:self.theme.previewUrl];
    [self.navigationController pushViewController:livePreviewController animated:YES];
}

- (IBAction)activatePressed:(id)sender {
    __block UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loading startAnimating];
    loading.center = CGPointMake(self.activateButton.bounds.size.width/2, self.activateButton.bounds.size.height/2);
    [self.activateButton setTitle:@"" forState:UIControlStateNormal];
    [self.activateButton addSubview:loading];
    
    [self.theme activateThemeWithSuccess:^{
        [loading removeFromSuperview];
        
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self showViewSite];
        } completion:nil];
        
    } failure:^(NSError *error) {
        [loading removeFromSuperview];
        
//        [WPError showAlertWithError:error];
    }];
}


@end
