//
//  NewLoginCompletedWalkthroughPage4ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "LoginCompletedWalkthroughPage4ViewController.h"
#import "WPNUXUtility.h"

@interface LoginCompletedWalkthroughPage4ViewController ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@end

@implementation LoginCompletedWalkthroughPage4ViewController

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
    
    self.titleLabel.text = NSLocalizedString(@"Get started!", @"NUX Second Walkthrough Page 4 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    self.titleLabel.layer.shadowRadius = 2.0;
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.titleLabel;
}


@end
