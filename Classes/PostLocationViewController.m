//
//  PostLocationViewController.m
//  WordPress
//
//  Created by Christopher Boyd on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PostLocationViewController.h"


@implementation PostLocationViewController
@synthesize map, locationController, buttonClose, buttonAction, toolbar;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	// If we have a predefined location, center the map on it immediately
	if([self isPostGeotagged])
	{
		// Post with previously determined Location data
		map.showsUserLocation = YES;
		CLLocation *postLocation = [self getPostLocation];
		[self locationUpdate:postLocation];
		PostAnnotation *pin = [[PostAnnotation alloc] initWithCoordinate:postLocation.coordinate];
		pin.title = @"Post Location";
		[self.map addAnnotation:pin];
		
		buttonAction.title = @"Remove Geotag";
	}
	else {
		// Begin updating our coordinates to keep track of any movement
		locationController = [[LocationController alloc] init];
		locationController.delegate = self;
		[locationController.locationManager startUpdatingLocation];
		
		buttonAction.title = @"Geotag";
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (IBAction)dismiss:(id)sender {
	[[locationController locationManager] stopUpdatingLocation];
	locationController = nil;
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark MKMapView Methods


#pragma mark -
#pragma mark Location Methods

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

- (BOOL)isPostGeotagged {
	if([self getPostLocation] != nil)
		return YES;
	else
		return NO;
}

- (IBAction)showLocationMapView:(id)sender {
	// Display the geotag view
	PostLocationViewController *locationView = [[PostLocationViewController alloc] initWithNibName:@"PostLocationViewController" bundle:nil];
	[self presentModalViewController:locationView animated:YES];
}

- (CLLocation *)getPostLocation {
	CLLocation *result = nil;
	double latitude = 0.0;
	double longitude = 0.0;
    NSArray *customFieldsArray = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"custom_fields"];
	
	// Loop through the post's custom fields
	for(NSDictionary *dict in customFieldsArray)
	{
		// Latitude
		if([[dict objectForKey:@"key"] isEqualToString:@"geo_latitude"])
			latitude = [[dict objectForKey:@"value"] doubleValue];
		
		// Longitude
		if([[dict objectForKey:@"key"] isEqualToString:@"geo_longitude"])
			longitude = [[dict objectForKey:@"value"] doubleValue];
		
		// If we have both lat and long, we have a geotag
		if((latitude != 0.0) && (longitude != 0.0))
		{
			result = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
			break;
		}
		else
			result = nil;
	}
	
	return result;
}

- (IBAction)buttonActionPressed:(id)sender {
	if([self isPostGeotagged])
		[self removeLocation];
	else
		[self addLocation];
}

- (void)removeLocation {
	NSMutableArray *customFieldsArray = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"custom_fields"];
	for(NSMutableDictionary *dict in customFieldsArray)
	{
		NSLog(@"dict: %@", [dict objectForKey:@"key"]);
		if(([[dict objectForKey:@"key"] isEqualToString:@"geo_latitude"]) ||
			([[dict objectForKey:@"key"] isEqualToString:@"geo_longitude"]) ||
			([[dict objectForKey:@"key"] isEqualToString:@"geo_accuracy"]) || 
			([[dict objectForKey:@"key"] isEqualToString:@"geo_public"]))
		{
			NSLog(@"removing dict: %@", [dict objectForKey:@"key"]);
			[dict removeObjectForKey:@"key"];
			[dict removeObjectForKey:@"value"];
		}
	}
	
	[[[BlogDataManager sharedDataManager] currentPost] setValue:customFieldsArray forKey:@"custom_fields"];
	
	[self dismiss:self];
}

- (void)addLocation {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSMutableArray *customFieldsArray;
	
	if([dm.currentPost valueForKey:@"custom_fields"] == nil)
		customFieldsArray = [[NSMutableArray alloc] init];
	else
		customFieldsArray = [dm.currentPost objectForKey:@"custom_fields"];
	
	// Format our values
	// Latitude
	NSString *latitude = [NSString stringWithFormat:@"%f", 
						  locationController.locationManager.location.coordinate.latitude];
	// Longitude
	NSString *longitude = [NSString stringWithFormat:@"%f", 
						   locationController.locationManager.location.coordinate.longitude];
	// Accuracy
	//NSString *accuracy = [NSString stringWithFormat:@"%f", 
	//					  locationController.locationManager.location.horizontalAccuracy];
	
	// Add latitude, accuracy, longitude, address, and public
	// WP API fields: geo_latitude, geo_longitude, geo_accuracy, geo_public
	//NSMutableArray *keys = [NSMutableArray arrayWithObjects:@"geo_latitude",@"geo_longitude", @"geo_accuracy", @"geo_public", nil];
	//NSMutableArray *objects = [NSMutableArray arrayWithObjects:latitude, longitude, accuracy, @"1", nil];
	NSMutableDictionary *dictLatitude = [[NSMutableDictionary alloc] init];
	[dictLatitude setValue:@"geo_latitude" forKey:@"key"];
	[dictLatitude setValue:latitude forKey:@"value"];
	[customFieldsArray addObject:dictLatitude];
	
	NSMutableDictionary *dictLongitude = [[NSMutableDictionary alloc] init];
	[dictLongitude setValue:@"geo_longitude" forKey:@"key"];
	[dictLongitude setValue:longitude forKey:@"value"];
	[customFieldsArray addObject:dictLongitude];
	
	NSMutableDictionary *dictAccuracy = [[NSMutableDictionary alloc] init];
	[dictAccuracy setValue:@"geo_accuracy" forKey:@"key"];
	[dictAccuracy setValue:[NSNumber numberWithInt:5] forKey:@"value"];
	[customFieldsArray addObject:dictAccuracy];
	
	NSMutableDictionary *dictPublic = [[NSMutableDictionary alloc] init];
	[dictPublic setValue:@"geo_public" forKey:@"key"];
	[dictPublic setValue:@"1" forKey:@"value"];
	[customFieldsArray addObject:dictPublic];
	
	// Send our modified custom fields back to BlogDataManager
	[dm.currentPost setValue:customFieldsArray forKey:@"custom_fields"];
	
	[self dismiss:self];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[map release];
	[buttonAction release];
	[toolbar release];
	[locationController release];
	[buttonClose release];
    [super dealloc];
}

@end
