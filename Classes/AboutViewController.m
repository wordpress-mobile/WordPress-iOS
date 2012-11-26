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

@interface AboutViewController (Private) 
- (void)dismiss;
- (void)openURLWithString:(NSString *)path;
@end

@implementation AboutViewController

@synthesize buttonsView;
@synthesize logoView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    self.navigationItem.title = NSLocalizedString(@"About", @"About this app (information page title)");
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    
    if( [self.navigationController.viewControllers count] == 1 )
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if( IS_IPHONE ) {
        if ( YES == UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ) {
            self.logoView.hidden = YES;
            CGRect frame = buttonsView.frame;
            frame.origin.y = -20.0f;
            self.buttonsView.frame = frame;
        } else {
            self.logoView.hidden = NO;
            CGRect frame = buttonsView.frame;
            frame.origin.y = 90.0f;
            self.buttonsView.frame = frame;
        }
    }
}


#pragma mark - Custom methods

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

-(void)viewTermsOfService:(id)sender {
	[self openURLWithString:@"http://wordpress.com/tos/"];
}

-(void)viewPrivacyPolicy:(id)sender {
	[self openURLWithString:@"http://automattic.com/privacy/"];
}

-(void)viewWebsite:(id)sender {
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
