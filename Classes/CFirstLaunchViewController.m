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
}

- (void)viewDidUnload
{
[super viewDidUnload];
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
}

@end
