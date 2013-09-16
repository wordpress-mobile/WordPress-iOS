//
//  GeneralWalkthroughPage2ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GeneralWalkthroughPage2ViewController.h"
#import "WPNUXUtility.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"

@interface GeneralWalkthroughPage2ViewController ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) IBOutlet UIImageView *bottomDivider;


@end

@implementation GeneralWalkthroughPage2ViewController

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
    
    self.titleLabel.text = NSLocalizedString(@"Publish whenever inspiration strikes", @"NUX First Walkthrough Page 2 Title");
    self.titleLabel.layer.shadowRadius = 2.0;
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.descriptionLabel.text = NSLocalizedString(@"Brilliant insight? Hilarious link? Perfect pic? Capture genius as it happens and post in real time.", @"NUX First Walkthrough Page 2 Description");
    self.descriptionLabel.layer.shadowRadius = 2.0;
    self.descriptionLabel.font = [WPNUXUtility descriptionTextFont];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.bottomDivider;
}

@end
