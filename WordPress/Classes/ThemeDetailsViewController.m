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
        self.title = theme.name;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.themeControlsView];
    
    // This seems redundant with the title of the navbar being the same
    // Also some theme names are long. Recommend that this is just static: Details / Theme Details
    self.themeName.text = self.theme.name;
    self.themeName.font = [WPStyleGuide largePostTitleFont];
    
    self.activateButton.layer.cornerRadius = 4.0f;
    self.activateButton.titleLabel.font = [WPStyleGuide regularTextFont];
    self.livePreviewButton.titleLabel.font = self.activateButton.titleLabel.font;
    self.livePreviewButton.layer.cornerRadius = self.activateButton.layer.cornerRadius;
    
    UILabel *tagsTitle = [[UILabel alloc] initWithFrame:CGRectMake(self.livePreviewButton.frame.origin.x, CGRectGetMaxY(self.themeControlsView.frame) + 10, 0, 0)];
    tagsTitle.text = NSLocalizedString(@"Tags", @"Title for theme tags");
    tagsTitle.font = [WPStyleGuide postTitleFont];
    [tagsTitle sizeToFit];
    [self.view addSubview:tagsTitle];
    
    UILabel *tags = [[UILabel alloc] initWithFrame:CGRectMake(tagsTitle.frame.origin.x, CGRectGetMaxY(tagsTitle.frame), self.view.frame.size.width-tagsTitle.frame.origin.x*2, 0)];
    tags.text = [self.theme.tags componentsJoinedByString:@", "];
    tags.numberOfLines = 0;
    tags.font = [WPStyleGuide regularTextFont];
    [tags sizeToFit];
    [self.view addSubview:tags];
    
    UILabel *detailsTitle = [[UILabel alloc] initWithFrame:CGRectMake(tags.frame.origin.x, CGRectGetMaxY(tags.frame) + 20, 0, 0)];
    detailsTitle.text = NSLocalizedString(@"Details", @"Title for theme details");
        detailsTitle.font = tagsTitle.font;
    [detailsTitle sizeToFit];
    [self.view addSubview:detailsTitle];
    
    UILabel *detailsText = [[UILabel alloc] initWithFrame:CGRectMake(detailsTitle.frame.origin.x, CGRectGetMaxY(detailsTitle.frame), tags.frame.size.width, 0)];
    detailsText.text = self.theme.details;
    detailsText.numberOfLines = 0;
    detailsText.font = tags.font;
    [detailsText sizeToFit];
    [self.view addSubview:detailsText];
    
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(detailsText.frame));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // TODO replace with real image cacher
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:self.theme.screenshotUrl] withSuccess:^(UIImage *image) {
        self.screenshot.image = image;
    } failure:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)livePreviewPressed:(id)sender {
    // TODO Open WPWebViewController for site with live preview
    WPWebViewController *livePreviewController = [[WPWebViewController alloc] init];
    livePreviewController.username = [WPAccount defaultWordPressComAccount].username;
    livePreviewController.password = [WPAccount defaultWordPressComAccount].password;
    livePreviewController.url = [NSURL URLWithString:self.theme.previewUrl];
    [self.navigationController pushViewController:livePreviewController animated:true];
}

- (IBAction)activatePressed:(id)sender {
    // TODO Activate theme on site
    
}

@end
