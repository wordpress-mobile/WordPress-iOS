//
//  WPFriendFinderViewController.m
//  WordPress
//
//  Created by Beau Collins on 5/31/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPFriendFinderViewController.h"
#import "UIBarButtonItem+Styled.h"
#import "ReachabilityUtils.h"

typedef void (^DismissBlock)(int buttonIndex);
typedef void (^CancelBlock)();


@interface WPFriendFinderViewController ()

@property (nonatomic, copy) DismissBlock dismissBlock;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation WPFriendFinderViewController

@synthesize dismissBlock;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // register for a notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(facebookDidLogIn:) name:kFacebookLoginNotificationName object:nil];
    [nc addObserver:self selector:@selector(facebookDidNotLogIn:) name:kFacebookNoLoginNotificationName object:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:[WPStyleGuide barButtonStyleForDone]
                                                                                           target:self 
                                                                                           action:@selector(dismissFriendFinder:)];
    if (!IS_IOS7) {
        [UIBarButtonItem styleButtonAsPrimary:self.navigationItem.rightBarButtonItem];        
    }
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    CGRect f1 = self.activityView.frame;
    CGRect f2 = self.view.frame;
    f1.origin.x = (f2.size.width / 2.0f) - (f1.size.width / 2.0f);
    f1.origin.y = (f2.size.height / 2.0f) - (f1.size.height / 2.0f);
    self.activityView.frame = f1;
    
    [self.view addSubview:self.activityView];
}

- (void)dismissFriendFinder:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIWebView Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if ([[[webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML.length"] numericValue] integerValue] == 0) {
        [self.activityView startAnimating];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityView stopAnimating];
}

@end
