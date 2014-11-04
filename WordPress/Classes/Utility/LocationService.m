#import "LocationService.h"

#import <CoreLocation/CoreLocation.h>

static LocationService *instance;
static NSInteger const LocationHorizontalAccuracyThreshold = 100; // Meters
static NSInteger const LocationServiceTimeoutDuration = 5; // Seconds
NSString *const LocationServiceErrorDomain = @"LocationServiceErrorDomain";

@interface LocationService()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSMutableArray *completionBlocks;
@property (nonatomic, strong) NSTimer *timeoutClock;
@property (nonatomic, readwrite) BOOL locationServiceRunning;
@property (nonatomic, strong) CLLocation *lastUpdatedLocation;
@property (nonatomic, strong, readwrite) CLLocation *lastGeocodedLocation;
@property (nonatomic, strong, readwrite) NSString *lastGeocodedAddress;

@end

@implementation LocationService

+ (instancetype)sharedService
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LocationService alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.locationManager.distanceFilter = 0;
        self.geocoder = [[CLGeocoder alloc] init];
        self.completionBlocks = [NSMutableArray array];
    }

    return self;
}

#pragma mark - Instance Methods

- (BOOL)locationServicesDisabled
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        return YES;
    }
    if (status == kCLAuthorizationStatusNotDetermined && [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    return NO;
}

- (void)getCurrentLocationAndAddress:(LocationServiceCompletionBlock)completionBlock
{
    if (completionBlock) {
        [self.completionBlocks addObject:completionBlock];
    }
    self.lastGeocodedAddress = nil;
    self.lastGeocodedLocation = nil;
    [self startUpdatingLocation];
}

- (void)getAddressForLocation:(CLLocation *)location completion:(LocationServiceCompletionBlock)completionBlock
{
    if (completionBlock) {
        [self.completionBlocks addObject:completionBlock];
    }

    // Skip the address lookup if this is not a new location
    if ([self hasAddressForLocation:location]) {
        [self addressUpdated:self.lastGeocodedAddress forLocation:self.lastGeocodedLocation error:nil];
        return;
    }

    self.locationServiceRunning = YES;
    self.lastGeocodedAddress = nil;
    self.lastGeocodedLocation = nil;
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString *address;
        if (placemarks) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            if (placemark.addressDictionary) {
                address = [[placemark.addressDictionary arrayForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
            } else {
                // Fallback, just in case.
                address = placemark.name;
            }
        } else {
            DDLogError(@"Reverse geocoder failed for coordinate (%.6f, %.6f): %@",
                       location.coordinate.latitude,
                       location.coordinate.longitude,
                       [error localizedDescription]);

            address = [NSString stringWithString:NSLocalizedString(@"Location unknown", @"Used when geo-tagging posts, if the geo-tagging failed.")];
        }
        [self addressUpdated:address forLocation:location error:error];
    }];
}

- (BOOL)hasAddressForLocation:(CLLocation *)location
{
    if (self.lastGeocodedAddress != nil && [self.lastGeocodedLocation distanceFromLocation:location] <= LocationHorizontalAccuracyThreshold) {
        return YES;
    }
    return NO;
}

#pragma mark - Private Methods

- (void)getAddressForLocation:(CLLocation *)location
{
    [self getAddressForLocation:location completion:nil];
}

- (void)addressUpdated:(NSString *)address forLocation:(CLLocation *)location error:(NSError *)error
{
    self.locationServiceRunning = NO;
    self.lastGeocodedAddress = address;
    self.lastGeocodedLocation = location;

    for (NSInteger i = 0; i < [self.completionBlocks count]; i++) {
        LocationServiceCompletionBlock block = [self.completionBlocks objectAtIndex:i];
        block(location, address, error);
    }

    [self.completionBlocks removeAllObjects];
}

- (void)serviceFailed:(NSError *)error
{
    DDLogError(@"Error finding location: %@", error);
    [self stopUpdatingLocation];
    self.locationServiceRunning = NO;
    for (NSInteger i = 0; i < [self.completionBlocks count]; i++) {
        LocationServiceCompletionBlock block = [self.completionBlocks objectAtIndex:i];
        block(nil, nil, error);
    }
    [self.completionBlocks removeAllObjects];
}

- (void)startUpdatingLocation
{
    [self stopUpdatingLocation];
    self.locationServiceRunning = YES;
    [self.locationManager startUpdatingLocation];
    self.timeoutClock = [NSTimer scheduledTimerWithTimeInterval:LocationServiceTimeoutDuration
                                                         target:self
                                                       selector:@selector(timeoutUpdatingLocation)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
    [self.timeoutClock invalidate];
    self.timeoutClock = nil;
    self.lastUpdatedLocation = nil;
}

- (void)timeoutUpdatingLocation
{
    CLLocation *lastLocation;
    [self stopUpdatingLocation];
#if TARGET_IPHONE_SIMULATOR
    lastLocation = self.locationManager.location;
#endif
    if (lastLocation) {
        [self getAddressForLocation:lastLocation];
    } else {
        NSString *description = NSLocalizedString(@"Unable to find the current location in a reasonable amount of time.", @"Error message that is displayed when the user's current location could not be found after a few seconds.");
        NSError *error = [NSError errorWithDomain:LocationServiceErrorDomain
                                             code:LocationServiceErrorLocationServiceTimedOut
                                         userInfo:@{NSLocalizedDescriptionKey:description}];
        [self serviceFailed:error];
    }
}

#pragma mark - CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self serviceFailed:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject]; // The last item is the most recent.

#if TARGET_IPHONE_SIMULATOR
    [self stopUpdatingLocation];
    [self getAddressForLocation:location];
#else
    if (location.horizontalAccuracy > 0 && location.horizontalAccuracy < LocationHorizontalAccuracyThreshold) {
        [self stopUpdatingLocation];
        [self getAddressForLocation:location];
    } else {
        self.lastUpdatedLocation = location;
    }
#endif
}

@end
