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
@property (weak, nonatomic) IBOutlet UILabel *themeName;
@property (weak, nonatomic) IBOutlet UIImageView *screenshot;
@property (weak, nonatomic) IBOutlet UIButton *livePreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *activateButton;

@property (nonatomic, strong) Theme *theme;
@property (nonatomic, weak) UILabel *tagCloud;

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
    
    [self.view addSubview:self.themeControlsView];
    
    self.themeName.text = self.theme.name;
    self.themeName.font = [WPStyleGuide largePostTitleFont];
    [self.themeName sizeToFit];
    
    self.livePreviewButton.titleLabel.font = [WPStyleGuide regularTextFont];
    self.livePreviewButton.layer.cornerRadius = 4.0f;
    
    if ([self.theme isCurrentTheme]) {
        [self showAsCurrentTheme];
    } else {
        self.activateButton.layer.cornerRadius = self.livePreviewButton.layer.cornerRadius;
        self.activateButton.titleLabel.font = self.livePreviewButton.titleLabel.font;
    }

    // Should just be text and no background if iOS7
    [self.livePreviewButton setBackgroundColor:[WPStyleGuide baseDarkBlue]];
    
    UILabel *detailsTitle = [[UILabel alloc] initWithFrame:CGRectMake(self.livePreviewButton.frame.origin.x, CGRectGetMaxY(self.themeControlsView.frame) + 10, 0, 0)];
    detailsTitle.text = NSLocalizedString(@"Details", @"Title for theme details");
    detailsTitle.font = [WPStyleGuide postTitleFont];
    [detailsTitle sizeToFit];
    [self.view addSubview:detailsTitle];
    
    UILabel *detailsText = [[UILabel alloc] initWithFrame:CGRectMake(detailsTitle.frame.origin.x, CGRectGetMaxY(detailsTitle.frame), self.view.frame.size.width-detailsTitle.frame.origin.x*2, 0)];
    detailsText.text = self.theme.details;
    detailsText.numberOfLines = 0;
    detailsText.font = [WPStyleGuide regularTextFont];
    [detailsText sizeToFit];
    [self.view addSubview:detailsText];
    
    UILabel *tagsTitle = [[UILabel alloc] initWithFrame:CGRectMake(detailsTitle.frame.origin.x, CGRectGetMaxY(detailsText.frame) + 20, 0, 0)];
    tagsTitle.text = NSLocalizedString(@"Tags", @"Title for theme tags");
    tagsTitle.font = detailsTitle.font;
    [tagsTitle sizeToFit];
    [self.view addSubview:tagsTitle];
    
    UILabel *tags = [[UILabel alloc] initWithFrame:CGRectMake(tagsTitle.frame.origin.x, CGRectGetMaxY(tagsTitle.frame), detailsText.frame.size.width, 0)];
    tags.text = [self formattedTags];
    tags.numberOfLines = 0;
    tags.font = [WPStyleGuide subtitleFont];
    [tags sizeToFit];
    [self.view addSubview:tags];
    
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(tags.frame));
    
    // TODO replace with real image cacher
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:self.theme.screenshotUrl] withSuccess:^(UIImage *image) {
        self.screenshot.image = image;
    } failure:nil];
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

- (void)showAsCurrentTheme {
    // Remove activate theme button, and live preview becomes the 'View Site' button
    [self.livePreviewButton setTitle:NSLocalizedString(@"View Site", @"") forState:UIControlStateNormal];
    CGRect f = self.livePreviewButton.frame;
    f.size.width = CGRectGetMaxX(self.activateButton.frame) - self.livePreviewButton.frame.origin.x;
    self.livePreviewButton.frame = f;
    self.activateButton.alpha = 0;
}

- (IBAction)livePreviewPressed:(id)sender {
    // Live preview URL yields the same result as 'view current site'.
    WPWebViewController *livePreviewController = [[WPWebViewController alloc] init];
    livePreviewController.username = [WPAccount defaultWordPressComAccount].username;
    livePreviewController.password = [WPAccount defaultWordPressComAccount].password;
    [livePreviewController setWpLoginURL:[NSURL URLWithString:self.theme.blog.loginUrl]];
    livePreviewController.url = [NSURL URLWithString:self.theme.previewUrl];
    [self.navigationController pushViewController:livePreviewController animated:true];
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
            [self showAsCurrentTheme];
        } completion:nil];
        
    } failure:^(NSError *error) {
        [loading removeFromSuperview];
        
        [WPError showAlertWithError:error];
    }];
}


@end
