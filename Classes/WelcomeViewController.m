    //
//  WelcomeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WelcomeViewController.h"
#import "BlogsViewController.h"
#import "WebSignupViewController.h"
#import "QuartzCore/QuartzCore.h"

@implementation WelcomeViewController

@synthesize haveAccount;
@synthesize newUser, navigationController, window, webSignupViewController, tagline;

- (void)viewDidLoad {
    [super viewDidLoad];
    
	tagline.text = [NSString stringWithFormat:@"%@%@%@", @"Start blogging from your ", [[UIDevice currentDevice] model], @" in seconds."];

	
}

-(IBAction) loadAccountSignup:(id) sender{
	self.webSignupViewController = [[WebSignupViewController alloc] initWithNibName:@"WebSignupViewController" bundle:[NSBundle mainBundle]];
	
	//[self.view.superview makeKeyAndVisible];
	
	UIView *currentView = self.view;
	UIView *theWindow = [currentView superview];
	
	// remove the current view and replace with myView1
	//[currentView removeFromSuperview];
	[self.view.superview addSubview:[webSignupViewController view]];
	
	// set up an animation for the transition between the views
	CATransition *animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionPush];
	[animation setSubtype:kCATransitionFromRight];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	
	[[theWindow layer] addAnimation:animation forKey:@"CancelWebSignup"];
}

-(IBAction) loadEditBlog:(id) sender{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.8];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view.superview cache:YES];
	
	[UIView commitAnimations];
	[[self view]removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[haveAccount release];
	[newUser release];
    [super dealloc];
}

@end
