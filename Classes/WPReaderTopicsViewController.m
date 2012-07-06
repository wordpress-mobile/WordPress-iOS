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

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Topics", @"");
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                  target:self 
                                                                                  action:@selector(cancelSelection:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    [cancelButton release];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (IS_IPAD) {
        return YES;
    }

    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
}


- (void) cancelSelection:(id)sender {
    [self.delegate topicsController:self didDismissSelectingTopic:nil withTitle:nil];
}


- (void)loadTopicsPage {    
    [self loadURL:kMobileReaderTopicsURL];
}


- (void)selectTopic:(NSString *)topic :(NSString *)title {
    [self.delegate topicsController:self didDismissSelectingTopic:topic withTitle:title];
}


- (void)setSelectedTopic:(NSString *)topicId {
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.setSelectedTopic('%@')", topicId]];
}


- (void)enableFriendFinder {
    NSLog(@"Enable the Friend Finder");
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.enableFriendFinder()"];
}

- (void)openFriendFinder {
    WPFriendFinderViewController *friendFinder = [[WPFriendFinderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
    [self.navigationController pushViewController:friendFinder animated:YES];
    [friendFinder release];
    [friendFinder loadURL:kMobileReaderFFURL];
}


- (NSString *)selectedTopicTitle {
    return [self.webView stringByEvaluatingJavaScriptFromString:@"document.selectedTopicTitle()"];
}

@end
