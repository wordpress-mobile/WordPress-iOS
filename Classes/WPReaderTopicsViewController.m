//
//  WPReaderTopicsViewController.m
//  WordPress
//
//  Created by Beau Collins on 1/19/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPReaderTopicsViewController.h"
#import "WordPressAppDelegate.h"
#import "WPFriendFinderViewController.h"

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
    
    UIBarButtonItem *ffButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(openFriendFinder)];
    
    self.navigationItem.leftBarButtonItem = ffButton;
    [ffButton release];
    

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
    
    [self loadURL:kMobileReaderTopicsURL];
}


- (void)selectTopic:(NSString *)topic :(NSString *)title
{
    [self.delegate topicsController:self didDismissSelectingTopic:topic withTitle:title];
}

- (void)setSelectedTopic:(NSString *)topicId
{
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.setSelectedTopic('%@')", topicId]];
    
}

- (void)openFriendFinder
{
    WPFriendFinderViewController *friendFinder = [[WPFriendFinderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
    [self.navigationController pushViewController:friendFinder animated:YES];
    [friendFinder release];
    [friendFinder loadURL:kMobileReaderFFURL];
}

- (NSString *)selectedTopicTitle {
    return [self.webView stringByEvaluatingJavaScriptFromString:@"document.selectedTopicTitle()"];
}


@end
