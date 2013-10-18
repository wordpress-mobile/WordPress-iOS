//
//  AboutViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "AboutViewController.h"
#import "ReachabilityUtils.h"
#import "WPWebViewController.h"

@interface AboutViewController()

@property (nonatomic, strong) IBOutlet UIView *logoView;
@property (nonatomic, strong) IBOutlet UIView *buttonsView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UILabel *publisherLabel;
@property (nonatomic, strong) IBOutlet UIButton *viewWebsiteButton;
@property (nonatomic, strong) IBOutlet UIButton *tosButton;
@property (nonatomic, strong) IBOutlet UIButton *privacyPolicyButton;

@end

@implementation AboutViewController

@synthesize buttonsView;
@synthesize logoView;

CGFloat const AboutViewLandscapeButtonsY = -20.0f;
CGFloat const AboutViewPortraitButtonsY = 90.0f;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"About", @"About this app (information page title)");

    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    self.titleLabel.text = NSLocalizedString(@"WordPress for iOS", nil);
    self.titleLabel.font = [WPStyleGuide largePostTitleFont];
    self.titleLabel.textColor = [WPStyleGuide whisperGrey];
    
    self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    self.versionLabel.font = [WPStyleGuide postTitleFont];
    self.versionLabel.textColor = [WPStyleGuide whisperGrey];

    self.publisherLabel.font = [WPStyleGuide regularTextFont];
    self.publisherLabel.textColor = [WPStyleGuide whisperGrey];
    
    self.viewWebsiteButton.titleLabel.font = [WPStyleGuide subtitleFont];
    self.viewWebsiteButton.titleLabel.textColor = [WPStyleGuide whisperGrey];
    
    if (IS_IOS7) {
        [self.tosButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.tosButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        [self.tosButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
    } else {
        self.tosButton.titleLabel.textColor = [WPStyleGuide whisperGrey];
    }
    self.tosButton.titleLabel.font = [WPStyleGuide postTitleFont];
    [self.tosButton setTitle:NSLocalizedString(@"Terms of Service", nil) forState:UIControlStateNormal];
    
    if (IS_IOS7) {
        [self.privacyPolicyButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.privacyPolicyButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        [self.privacyPolicyButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
    } else  {
        self.privacyPolicyButton.titleLabel.textColor = [WPStyleGuide whisperGrey];
    }
    [self.privacyPolicyButton setTitle:NSLocalizedString(@"Privacy Policy", nil) forState:UIControlStateNormal];
    self.privacyPolicyButton.titleLabel.font = [WPStyleGuide postTitleFont];
    
    if([self.navigationController.viewControllers count] == 1) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (IS_IPHONE) {
        CGRect frame = buttonsView.frame;
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            self.logoView.hidden = YES;
            frame.origin.y = AboutViewLandscapeButtonsY;
        } else {
            self.logoView.hidden = NO;
            frame.origin.y = AboutViewPortraitButtonsY;
        }
        self.buttonsView.frame = frame;
    }
}


#pragma mark - Custom methods

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)viewTermsOfService:(id)sender {
	[self openURLWithString:@"http://wordpress.com/tos/"];
}

-(IBAction)viewPrivacyPolicy:(id)sender {
	[self openURLWithString:@"http://automattic.com/privacy/"];
}

-(IBAction)viewWebsite:(id)sender {
    [self openURLWithString:@"http://automattic.com/"];
}

- (void)openURLWithString:(NSString *)path {
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:[NSURL URLWithString:path]];
    [self.navigationController pushViewController:webViewController animated:YES];
}

@end
