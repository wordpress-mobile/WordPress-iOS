//
//  GeneralWalkthroughPage1ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GeneralWalkthroughPage1ViewController.h"
#import "WPNUXUtility.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "AboutViewController.h"

@interface GeneralWalkthroughPage1ViewController ()

@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *swipeToContinueLabel;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIImageView *helpButton;
@property (nonatomic, strong) IBOutlet UIImageView *bottomDivider;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;


@end

@implementation GeneralWalkthroughPage1ViewController

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

    self.titleLabel.text = NSLocalizedString(@"Welcome to WordPress", @"NUX First Walkthrough Page 1 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    self.titleLabel.layer.shadowRadius = 2.0;

    self.descriptionLabel.text = NSLocalizedString(@"Hold the web in the palm of your hand. Full publishing power in a pint-sized package.", @"NUX First Walkthrough Page 1 Description");
    self.descriptionLabel.font = [WPNUXUtility descriptionTextFont];
    self.descriptionLabel.layer.shadowRadius = 2.0;
    
    self.swipeToContinueLabel.text = [NSLocalizedString(@"swipe to continue", nil) uppercaseString];
    self.swipeToContinueLabel.font = [WPNUXUtility swipeToContinueFont];
        
    [WPNUXUtility configurePageControlTintColors:self.pageControl];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.bottomDivider;
}

#pragma mark IBAction Methods

- (IBAction)clickedInfoButton:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedInfo];
    AboutViewController *aboutViewController = [[AboutViewController alloc] init];
	aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    nc.navigationBar.translucent = NO;
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
	[self.navigationController setNavigationBarHidden:YES];
}


@end
