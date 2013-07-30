//
//  CreateAccountAndBlogPage3ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogPage3ViewController.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"

@interface CreateAccountAndBlogPage3ViewController ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *finalLineSeparator;
@property (nonatomic, strong) IBOutlet UILabel *emailConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *usernameConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteTitleConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteAddressConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteLanguageConfirmation;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *previousButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;


@end

@implementation CreateAccountAndBlogPage3ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = NSLocalizedString(@"Review your information", @"NUX Create Account Page 3 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.emailConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.usernameConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteTitleConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteAddressConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteLanguageConfirmation.font = [WPNUXUtility confirmationLabelFont];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.finalLineSeparator;
}

@end
