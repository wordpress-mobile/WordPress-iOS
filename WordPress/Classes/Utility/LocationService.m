#import "LocationService.h"

#import <CoreLocation/CoreLocation.h>
#import "WordPress-Swift.h"

static LocationService *instance;
NSString *const LocationServiceErrorDomain = @"LocationServiceErrorDomain";

@interface LocationService()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSMutableArray *completionBlocks;
@property (nonatomic, readwrite) BOOL locationServiceRunning;
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
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = 0;
        _geocoder = [[CLGeocoder alloc] init];
        _completionBlocks = [NSMutableArray array];
    }

    return self;
}

#pragma mark - Instance Methods

- (BOOL)locationServicesDisabled
{
    return ![CLLocationManager locationServicesEnabled];
}

- (BOOL)locationServicesDenied
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        return YES;
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
    [self.locationManager requestWhenInUseAuthorization];
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
            CLPlacemark *placemark = [placemarks firstObject];
            address = [placemark formattedAddress];
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
    if (self.lastGeocodedAddress != nil && [self.lastGeocodedLocation distanceFromLocation:location] <= kCLLocationAccuracyHundredMeters) {
        return YES;
    }
    return NO;
}

- (void)searchPlacemarksWithQuery:(NSString *)query completion:(LocationServicePlacemarksCompletionBlock)completionBlock
{
    NSParameterAssert(query);
    NSParameterAssert(completionBlock);
    [self.geocoder geocodeAddressString:query completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
        if (placemarks == nil) {
            completionBlock(nil, error);
            return;
        }
        
        completionBlock(placemarks, nil);
    }];
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

    for (LocationServiceCompletionBlock block in self.completionBlocks) {
        block(location, address, error);
    }

    [self.completionBlocks removeAllObjects];
}

- (void)serviceFailed:(NSError *)error
{
    DDLogError(@"Error finding location: %@", error);
    [self stopUpdatingLocation];
    self.locationServiceRunning = NO;
    for (LocationServiceCompletionBlock block in self.completionBlocks) {
        block(nil, nil, error);
    }
    [self.completionBlocks removeAllObjects];
}

- (void)startUpdatingLocation
{
    [self stopUpdatingLocation];
    self.locationServiceRunning = YES;
    [self.locationManager requestLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
    self.locationServiceRunning = NO;
}

#pragma mark - CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self serviceFailed:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject]; // The last item is the most recent.
    [self stopUpdatingLocation];
    [self getAddressForLocation:location];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        [self serviceFailed:[NSError errorWithDomain:LocationServiceErrorDomain code:LocationServiceErrorPermissionDenied userInfo:nil]];
    }
}

#pragma mark - Show alert for location errors

- (void)showAlertForLocationServicesDisabled
{
    [self showAlertForLocationError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil]];
}

- (void)showAlertForLocationError:(NSError *)error
{
    NSString *title = NSLocalizedString(@"Location", @"Title for alert when a generic error happened when trying to find the location of the device");
    NSString *message = NSLocalizedString(@"There was a problem when trying to access your location. Please try again later.",  @"Explaining to the user there was an error trying to obtain the current location of the user.");
    NSString *cancelText = NSLocalizedString(@"OK", "");
    NSString *otherButtonTitle = nil;
    if (error.domain == kCLErrorDomain && error.code == kCLErrorDenied) {
        if ([CLLocationManager locationServicesEnabled]) {
            otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
            message = NSLocalizedString(@"WordPress needs permission to access your device's current location in order to add it to your post. Please update your privacy settings.",  @"Explaining to the user why the app needs access to the device location.");
            cancelText = NSLocalizedString(@"Cancel", "");
        } else {
            message = NSLocalizedString(@"Location Services must be enabled before WordPress can add your current location. Please enable Location Services from the Settings app.",  @"Explaining to the user that location services need to be enable in order to geotag a post.");
        }
    }
    if (error.domain == LocationServiceErrorDomain && error.code == LocationServiceErrorPermissionDenied) {
        // The user explicitily denied a permission request so not worth to show an alert
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:cancelText style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:okAction];
    
    if (otherButtonTitle) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL];
        }];
        [alertController addAction:otherAction];
    }
    [alertController presentFromRootViewController];
}

@end
