#import "LocationController.h"

@implementation LocationController

@synthesize locationManager, delegate;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self; // send loc updates to myself
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
	[self setHasLocation:YES];
    [self.delegate locationUpdate:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	[self setHasLocation:NO];
    [self.delegate locationError:error];
}

- (void)dealloc {
    [self.locationManager release];
    [super dealloc];
}

@end