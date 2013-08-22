/*
 * ThemeDetailsViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeDetailsViewController.h"

@interface ThemeDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *themeTitle;
@property (weak, nonatomic) IBOutlet UIImageView *themePreviewImageView;
@property (nonatomic, strong) Theme *theme;

@end

@implementation ThemeDetailsViewController

- (id)initWithTheme:(Theme *)theme {
    self = [super init];
    if (self) {
        self.theme = theme;
//        self.title = theme.title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)livePreviewPressed:(id)sender {
    
}

- (IBAction)activatePressed:(id)sender {
    
}

@end
