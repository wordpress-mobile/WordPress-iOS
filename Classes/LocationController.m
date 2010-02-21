#import "LocationController.h"

@implementation LocationController

@synthesize locationManager, delegate;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		
		// Always send location updates to myself.
        self.locationManager.delegate = self;
    }
    return self;
}

- (BOOL)hasLocation {
	return hasLocation;
}

- (void)setHasLocation:(BOOL)input {
	hasLocation = input;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	// Called whenever we receive a GPS location update.
	[self setHasLocation:YES];
    [self.delegate locationUpdate:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	// Called whenever we receive a GPS location failure.
	[self setHasLocation:NO];
    [self.delegate locationError:error];
}

- (void)dealloc {
    [self.locationManager release];
    [super dealloc];
}

@end