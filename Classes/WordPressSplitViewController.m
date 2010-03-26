//
//  WordPressSplitViewController.m
//  WordPress
//
//  Created by Jonathan Wight on 03/02/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "WordPressSplitViewController.h"

#import "UIPopoverController_Extensions.h"

@implementation WordPressSplitViewController

- (void)viewDidLoad
{
[super viewDidLoad];

self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
[super viewDidAppear:animated];
//


NSLog(@"%d", UIInterfaceOrientationIsPortrait(self.masterNavigationController.interfaceOrientation));
//if (self.interfaceOrientation == UIInterfaceOrientationPortrait
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
	return YES;
}

- (UINavigationController *)masterNavigationController
{
id theObject = [self.viewControllers objectAtIndex:0];
NSAssert([theObject isKindOfClass:[UINavigationController class]], @"That is not a nav controller");
return(theObject);
}

- (UINavigationController *)detailNavigationController
{
id theObject = [self.viewControllers objectAtIndex:1];
NSAssert([theObject isKindOfClass:[UINavigationController class]], @"That is not a nav controller");
return(theObject);
}

// Called when a button should be added to a toolbar for a hidden view controller
- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
UINavigationItem *theNavigationItem = [[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem];
[barButtonItem setTitle:@"My Blog"];
[theNavigationItem setLeftBarButtonItem:barButtonItem animated:YES];
//[UIPopoverController setCurrentPopoverController:pc];
}

// Called when the view is shown again in the split view, invalidating the button and popover controller
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
[[[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem] setLeftBarButtonItem:NULL animated:YES];

[UIPopoverController setCurrentPopoverController:NULL];
}

// Called when the view controller is shown in a popover so the delegate can take action like hiding other popovers.
- (void)splitViewController: (UISplitViewController*)svc popoverController: (UIPopoverController*)pc willPresentViewController:(UIViewController *)aViewController
{
	NSLog(@"Showing");
}

@end
