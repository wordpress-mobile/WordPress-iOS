//
//  CreateAccountAndBlogPage2ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogPage2ViewController.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"
#import "WPComLanguages.h"

@interface CreateAccountAndBlogPage2ViewController () {
    NSDictionary *_currentLanguage;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITextField *siteTitle;
@property (nonatomic, strong) IBOutlet UITextField *siteAddress;
@property (nonatomic, strong) IBOutlet UITextField *siteLanguage;
@property (nonatomic, strong) IBOutlet UIImageView *dropdownImage;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *previousButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;
@property (nonatomic, strong) IBOutlet UILabel *tosLabel;

@end

@implementation CreateAccountAndBlogPage2ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentLanguage = [WPComLanguages currentLanguage];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = NSLocalizedString(@"Create your first WordPress.com site", @"NUX Create Account Page 2 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.tosLabel.text = NSLocalizedString(@"You agree to the fascinating terms of service by pressing the next button.", @"NUX Create Account TOS Label");
    self.tosLabel.font = [WPNUXUtility tosLabelFont];
    self.tosLabel.layer.shadowRadius = 2.0;
    
    self.siteTitle.placeholder = NSLocalizedString(@"Site Title", @"NUX Create Account Page 2 Site Title Placeholder");
    self.siteTitle.font = [WPNUXUtility textFieldFont];
    
    self.siteAddress.placeholder = NSLocalizedString(@"Site Address (URL)", nil);
    self.siteAddress.font = [WPNUXUtility textFieldFont];
    
    self.siteLanguage.text = [_currentLanguage objectForKey:@"name"];
    self.siteLanguage.font = [WPNUXUtility textFieldFont];
    
    [self.previousButton setTitle:NSLocalizedString(@"Previous", nil) forState:UIControlStateNormal];
    
    [self.nextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.tosLabel;
}

@end
