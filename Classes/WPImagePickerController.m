//
//  WPImagePickerController.m
//  WordPress
//
//  Created by Janakiram on 01/10/08.
//  Copyright 2008 Prithvi Information Solutions. All rights reserved.
//

#import "WPImagePickerController.h"


@implementation WPImagePickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return ( interfaceOrientation == UIInterfaceOrientationPortrait );
//	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}


@end
