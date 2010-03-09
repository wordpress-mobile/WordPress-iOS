//
//  PostLocationViewController.m
//  WordPress
//
//  Created by Christopher Boyd on 2/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PostLocationViewController.h"


@implementation PostLocationViewController
@synthesize map, locationController, buttonClose, buttonRemove, buttonAdd, toolbar;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// If we have a predefined location, center the map on it immediately
	if([self isPostLocationAware])
	{
		// Post with previously determined Location data
		NSLog(@"custom fields:%@", [[[BlogDataManager sharedDataManager] currentPost] objectForKey:@"custom_fields"]);
		map.showsUserLocation = NO;
		CLLocationCoordinate2D postCoordinates = [self getPostLocation];
		CLLocation *postLocation = [[CLLocation alloc] initWithLatitude:postCoordinates.latitude longitude:postCoordinates.longitude];
		[self locationUpdate:postLocation];
		PostAnnotation *pin = [[PostAnnotation alloc] initWithCoordinate:[self getPostLocation]];
		pin.title = @"Post Location";
		[self.map addAnnotation:pin];
	
		buttonAdd.enabled = NO;
		buttonRemove.enabled = YES;
	}
	else {
		buttonAdd.enabled = YES;
		buttonRemove.enabled = NO;
		
		// Begin updating our coordinates to keep track of any movement
		locationController = [[LocationController alloc] init];
		locationController.delegate = self;
		[locationController.locationManager startUpdatingLocation];
	}
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

- (CLLocationCoordinate2D)getPostLocation {
	CLLocationCoordinate2D result;
	BOOL hasLatitude, hasLongitude = NO;
    NSArray *customFieldsArray = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"custom_fields"];
	
	for(NSDictionary *dict in customFieldsArray)
	{
		if([[dict objectForKey:@"key"] isEqualToString:@"geo_latitude"])
		{
			result.latitude = [[dict objectForKey:@"value"] doubleValue];
			hasLatitude = YES;
		}
		
		if([[dict objectForKey:@"key"] isEqualToString:@"geo_longitude"])
		{
			result.longitude = [[dict objectForKey:@"value"] doubleValue];
			hasLongitude = YES;
		}
		
		if(hasLatitude && hasLongitude)
			break;
	}
	
	return result;
}

- (BOOL)isPostLocationAware {
	BOOL result = NO;
	
    NSArray *customFieldsArray = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"custom_fields"];
	for(NSDictionary *dict in customFieldsArray)
	{
		if([dict objectForKey:@"geo_latitude"] != nil)
		{
			result = YES;
			break;
		}
	}
	
	NSLog(@"isPostLocationAware: %@", result?@"YES":@"NO");
	
	return result;
}

- (IBAction)removeLocation:(id)sender {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSMutableArray *customFieldsArray = [dm.currentPost valueForKey:@"custom_fields"];
	
	int dictsCount = [customFieldsArray count];
	
	for (int i = 0; i < dictsCount; i++) {
		NSString *tempKey = [[customFieldsArray objectAtIndex:i] objectForKey:@"key"];
		
		if(([tempKey rangeOfString:@"geo_latitude"].location != NSNotFound) || ([tempKey rangeOfString:@"geo_longitude"].location != NSNotFound)) {
			NSLog(@"Removing Location key: %@", tempKey);
			[customFieldsArray removeObjectAtIndex:i];
			i--;
			dictsCount = [customFieldsArray count];
		}
	}
	
	[dm.currentPost setValue:customFieldsArray forKey:@"custom_fields"];
	NSLog(@"custom fields after Location removal:%@", [dm.currentPost objectForKey:@"custom_fields"]);
	
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)updateLocation:(id)sender {
	locationController = [[LocationController alloc] init];
	locationController.delegate = self;
	[locationController.locationManager startUpdatingLocation];
	
	[self.map removeAnnotations:map.annotations];
	self.map.showsUserLocation = YES;
	[self addLocation:sender];
}

- (IBAction)addLocation:(id)sender {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSMutableArray *customFieldsArray;
	
	if([dm.currentPost valueForKey:@"custom_fields"] == nil)
		customFieldsArray = [[NSMutableArray alloc] init];
	else
		customFieldsArray = [dm.currentPost objectForKey:@"custom_fields"];
	
	// Remove existing values
	NSMutableArray *discardedItems = [NSMutableArray array];
	for(NSDictionary *dict in customFieldsArray)
	{
		if([dict objectForKey:@"geo_latitude"] != nil)
		{
			[discardedItems addObject:dict];
			break;
		}
		
		if([dict objectForKey:@"geo_longitude"] != nil)
		{
			[discardedItems addObject:dict];
			break;
		}
		
		if([dict objectForKey:@"geo_accuracy"] != nil)
		{
			[discardedItems addObject:dict];
			break;
		}
		
		if([dict objectForKey:@"geo_public"] != nil)
		{
			[discardedItems addObject:dict];
			break;
		}
	}
	[customFieldsArray removeObjectsInArray:discardedItems];
	
	// Format our values
	// Latitude
	NSString *latitude = [NSString stringWithFormat:@"%lf", 
						  locationController.locationManager.location.coordinate.latitude];
	// Longitude
	NSString *longitude = [NSString stringWithFormat:@"%lf", 
						   locationController.locationManager.location.coordinate.longitude];
	// Accuracy
	//NSString *accuracy = [NSString stringWithFormat:@"%f", 
	//					  locationController.locationManager.location.horizontalAccuracy];
	NSString *accuracy = [[NSString alloc] initWithString:@"0"];
	
	// Add latitude, accuracy, longitude, address, and public
	// WP API fields: geo_latitude, geo_longitude, geo_accuracy, geo_public
	NSMutableArray *keys = [NSMutableArray arrayWithObjects:@"geo_latitude",@"geo_longitude", @"geo_accuracy", @"geo_public", nil];
	NSMutableArray *objects = [NSMutableArray arrayWithObjects:latitude, longitude, accuracy, @"1", nil];
	NSDictionary *locationFields = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	
	// Send our modified custom fields back to BlogDataManager
	[customFieldsArray addObject:locationFields];
	[dm.currentPost setValue:customFieldsArray forKey:@"custom_fields"];	
	[dm autoSaveCurrentPost];
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[map release];
	[buttonAdd release];
	[toolbar release];
	[locationController release];
	[buttonClose release];
	[buttonRemove release];
    [super dealloc];
}

@end
