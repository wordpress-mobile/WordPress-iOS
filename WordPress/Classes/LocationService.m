//
//  LocationService.m
//  WordPress
//
//  Created by Eric Johnson on 2/5/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "LocationService.h"

#import <CoreLocation/CoreLocation.h>

// TODO: Set the NSLocationUsageDescription key in the plist.ini

static LocationService *instance;
static NSInteger const LocationHorizontalAccuracyThreshold = 50; // Meters

@interface LocationService()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) LocationServiceCompletionBlock completionBlock;
@property (nonatomic, readwrite) BOOL locationServiceRunning;
@property (nonatomic, strong, readwrite) CLLocation *lastGeocodedLocation;
@property (nonatomic, strong, readwrite) NSString *lastGeocodedAddress;
@end

@implementation LocationService

+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LocationService alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.locationManager.distanceFilter = 0;
        
        self.geocoder = [[CLGeocoder alloc] init];
    }
    
    return self;
}

#pragma mark - Instance Methods

- (BOOL)locationServicesDisabled {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        return YES;
    }
    return NO;
}

- (void)getCurrentLocationAndAddress:(LocationServiceCompletionBlock)completionBlock {
    self.completionBlock = completionBlock;
    [self startService];
}

- (void)getAddressForLocation:(CLLocation *)location completion:(LocationServiceCompletionBlock)completionBlock {
    if (completionBlock) {
        self.completionBlock = completionBlock;
    }
    
    // Skip the address lookup if this is not a new location
    if (self.lastGeocodedAddress && ([self.lastGeocodedLocation distanceFromLocation:location] >= LocationHorizontalAccuracyThreshold)) {
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
            if (placemark.subLocality) {
                address = [NSString stringWithFormat:@"%@, %@, %@", placemark.subLocality, placemark.locality, placemark.country];
            } else {
                address = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country];
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

- (void)locationUpdated:(CLLocation *)location {
    [self getAddressForLocation:location completion:nil];
}

- (void)addressUpdated:(NSString *)address forLocation:(CLLocation *)location error:(NSError *)error {
    self.locationServiceRunning = NO;
    self.lastGeocodedAddress = address;
    self.lastGeocodedLocation = location;
    if (self.completionBlock) {
        self.completionBlock(location, address, error);
        self.completionBlock = nil;
    }
}

- (void)serviceFailed:(NSError *)error {
    DDLogError(@"Error finding location: %@", error);
    if (self.completionBlock) {
        self.completionBlock(nil, nil, error);
        self.completionBlock = nil;
    }
}

- (void)startService {
    [self stopService];
    self.locationServiceRunning = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)stopService {
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self serviceFailed:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject]; // The last item is the most recent.
    
#if TARGET_IPHONE_SIMULATOR
    [self stopService];
    [self locationUpdated:location];
#else
    if (location.horizontalAccuracy > 0 && location.horizontalAccuracy < LocationHorizontalAccuracyThreshold) {
        [self stopService];
        [self locationUpdated:location];
    }
#endif
}

@end
