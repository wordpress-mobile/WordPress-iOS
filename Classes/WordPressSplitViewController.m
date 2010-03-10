//
//  WordPressSplitViewController.m
//  WordPress
//
//  Created by Jonathan Wight on 03/02/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "WordPressSplitViewController.h"

@implementation WordPressSplitViewController

@synthesize currentPopoverController;

- (void)viewDidLoad
{
[super viewDidLoad];

self.delegate = self;
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
	return YES;
}

- (UINavigationController *)masterNavigationController
{
return([self.viewControllers objectAtIndex:0]);
}

- (UINavigationController *)detailNavigationController
{
return([self.viewControllers objectAtIndex:1]);
}

// Called when a button should be added to a toolbar for a hidden view controller
- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
[barButtonItem setTitle:@"Items"];

NSLog(@"%@", self.detailNavigationController.topViewController.navigationItem);
[[[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem] setLeftBarButtonItem:barButtonItem animated:YES];

NSLog(@"%@", barButtonItem.title);

self.currentPopoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
NSLog(@"B");

[[[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem] setLeftBarButtonItem:NULL animated:YES];

self.currentPopoverController = NULL;
}

// Called when the view controller is shown in a popover so the delegate can take action like hiding other popovers.
- (void)splitViewController: (UISplitViewController*)svc popoverController: (UIPopoverController*)pc willPresentViewController:(UIViewController *)aViewController
{
NSLog(@"C");
}




@end
