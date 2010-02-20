//
//  PostLocationViewController.m
//  WordPress
//
//  Created by Christopher Boyd on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PostLocationViewController.h"


@implementation PostLocationViewController
@synthesize map, locationController, initialLocation, buttonClose;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	locationController = [[LocationController alloc] init];
	locationController.delegate = self;
	
	// If we have a predefined location, center the map on it immediately
	if(initialLocation != nil)
		[self locationUpdate:initialLocation];
	
	// Begin updating our coordinates to keep track of any movement
	[locationController.locationManager startUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (IBAction)dismiss:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Location updates

- (void)locationUpdate:(CLLocation *)location {
	UIBarButtonItem *currentLocationItem =
    [[[UIBarButtonItem alloc]
      initWithImage:[UIImage imageNamed:@"hasLocation.png"]
	  style:UIBarButtonItemStylePlain
	  target:self
	  action:@selector(locationButtonClicked:)] autorelease];
	
	self.navigationItem.rightBarButtonItem = currentLocationItem;
	[self centerMapOn:location];
}

- (void)locationError:(NSError *)error {
	UIAlertView *locationAlert = [[UIAlertView alloc]
								  initWithTitle:@"Location Error"
								  message:@"There was a problem updating your location. Please try again."
								  delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil];
	
	[locationAlert show];
	[locationAlert autorelease];
}

- (void)centerMapOn:(CLLocation *)location {
	if(map != nil)
	{
		MKCoordinateSpan span = {latitudeDelta: 0.00500, longitudeDelta: 0.00500};
		MKCoordinateRegion region = {location.coordinate, span};
		[self.map setRegion:region];
	}
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[map release];
	[locationController release];
	[initialLocation release];
    [super dealloc];
}

@end
