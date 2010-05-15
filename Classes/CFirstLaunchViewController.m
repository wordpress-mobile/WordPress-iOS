    //
//  CFirstLaunchViewController.m
//  WordPress
//
//  Created by Jonathan Wight on 03/05/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CFirstLaunchViewController.h"

#import "EditBlogViewController.h"
#import "BlogDataManager.h"
#import "CNewBlogSignupViewController.h"

#import "CPopoverManager.h"

@implementation CFirstLaunchViewController

- (void)dealloc
{
[super dealloc];
}

- (void)viewDidLoad
{
[super viewDidLoad];
//
self.title = @"WordPress";
if ([[BlogDataManager sharedDataManager] countOfBlogs] > 0)
	{
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)] autorelease];
	}
}

- (void)viewDidUnload
{
[super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated
{
[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
return YES;
}

- (void)didReceiveMemoryWarning
{
[super didReceiveMemoryWarning];
}

#pragma mark -

- (IBAction)actionNewBlog:(id)inSender
{
EditBlogViewController *blogDetailViewController = [[[EditBlogViewController alloc] initWithNibName:@"EditBlogViewController" bundle:nil] autorelease];

[[BlogDataManager sharedDataManager] makeNewBlogCurrent];

[self.navigationController pushViewController:blogDetailViewController animated:YES];

}

- (IBAction)actionSignupBlog:(id)inSender
{
CNewBlogSignupViewController *theSignupViewController = [[[CNewBlogSignupViewController alloc] initWithNibName:NULL bundle:NULL] autorelease];
[self.navigationController pushViewController:theSignupViewController animated:YES];

}

- (IBAction)actionCancel:(id)sender;
{
[self dismissModalViewControllerAnimated:YES];
}

@end
