//
//  WPReaderTopicsViewController.m
//  WordPress
//
//  Created by Beau Collins on 1/19/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPReaderTopicsViewController.h"
#import "WordPressAppDelegate.h"

@implementation WPReaderTopicsViewController

@synthesize delegate;


/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}
*/


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.

/*
- (void)loadView
{
    [super loadView];
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelection:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    [cancelButton release];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (DeviceIsPad()) {
        return YES;
    }

    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
}

- (void) cancelSelection:(id)sender
{
    [self.delegate topicsController:self didDismissSelectingTopic:nil withTitle:nil];
}

- (void)loadTopicsPage
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kMobileReaderTopicsURL]];
    NSDictionary *cookieHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookies cookiesForURL:request.URL]];
    [request setValue:appDelegate.applicationUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[cookieHeader valueForKey:@"Cookie"] forHTTPHeaderField:@"Cookie"];
    [self.webView loadRequest:[self authorizeHybridRequest:request]];
}


- (void)selectTopic:(NSString *)topic :(NSString *)title
{
    [self.delegate topicsController:self didDismissSelectingTopic:topic withTitle:title];
}

- (void)setSelectedTopic:(NSString *)topicId
{
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.setSelectedTopic('%@')", topicId]];
    
}

- (NSString *)selectedTopicTitle {
    return [self.webView stringByEvaluatingJavaScriptFromString:@"document.selectedTopicTitle()"];
}


@end
