//
//  FlippingViewController.m
//  WordPress
//
//  Created by Devin Chalmers on 3/5/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "FlippingViewController.h"


@implementation FlippingViewController

@synthesize frontViewController;
@synthesize backViewController;

@synthesize showingFront;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)viewDidLoad;
{
	[self.view addSubview:frontViewController.view];
}

- (void)viewWillAppear:(BOOL)animated;
{
	frontViewController.view.frame = self.view.frame;
	backViewController.view.frame = self.view.frame;
}

- (void)setShowingFront:(BOOL)newShowingFront animated:(BOOL)animated;
{
	showingFront = newShowingFront;
	
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		
		if (showingFront)
			[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
		else
			[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
		
		[UIView setAnimationDuration:0.3];
	}
	
	if (showingFront) {
		[backViewController viewWillDisappear:animated];
		[frontViewController viewWillAppear:animated];
		
		[backViewController.view removeFromSuperview];
		frontViewController.view.frame = self.view.frame;
		[self.view addSubview:frontViewController.view];
		
		[frontViewController viewDidAppear:animated];
		[backViewController viewDidDisappear:animated];
	} else {
		[frontViewController viewWillDisappear:animated];
		[backViewController viewWillAppear:animated];
		
		[frontViewController.view removeFromSuperview];
		backViewController.view.frame = self.view.frame;
		[self.view addSubview:backViewController.view];
		
		[backViewController viewDidAppear:animated];
		[frontViewController viewDidDisappear:animated];
	}
	
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)dealloc {
	[frontViewController release];
	[backViewController release];
	
    [super dealloc];
}


@end
