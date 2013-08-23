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

@interface ThemeDetailsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *themeTitle;
@property (weak, nonatomic) IBOutlet UIImageView *themePreviewImageView;
@property (weak, nonatomic) IBOutlet UIButton *livePreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *activateThemeButton;
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
    
    // This seems redundant with the title of the navbar being the same
    // Also some theme names are long. Recommend that this is just static: Details / Theme Details
    self.themeTitle.text = self.theme.name;
    self.themeTitle.font = [UIFont fontWithName:@"OpenSans" size:20.0f];
    
    self.activateThemeButton.layer.cornerRadius = 4.0f;
    self.activateThemeButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0f];
    self.livePreviewButton.titleLabel.font = self.activateThemeButton.titleLabel.font;
    self.livePreviewButton.layer.cornerRadius = self.activateThemeButton.layer.cornerRadius;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:self.theme.screenshotUrl] withSuccess:^(UIImage *image) {
        self.themePreviewImageView.image = image;
    } failure:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
