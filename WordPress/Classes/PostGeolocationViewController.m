//
//  PostGeolocationViewController.m
//  WordPress
//
//  Created by Eric Johnson on 1/23/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostGeolocationViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "Post.h"
#import "PostAnnotation.h"
#import "PostGeolocationView.h"

@interface PostGeolocationViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostGeolocationView *geoView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *reverseGeocoder;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) BOOL isUpdatingLocation;

@end

@implementation PostGeolocationViewController

- (void)dealloc {
    if (self.locationManager) {
		self.locationManager.delegate = nil;
		[self.locationManager stopUpdatingLocation];
	}
    if (self.reverseGeocoder) {
		[self.reverseGeocoder cancelGeocode];
	}
}

- (id)initWithPost:(Post *)post {
    self = [super init];
    if (self) {
        self.post = post;
        self.locationManager = [[CLLocationManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Automatically update the location for a new post
    BOOL isNewPost = (self.post.remoteStatus == AbstractPostRemoteStatusLocal) && !self.post.geolocation;
    BOOL postAllowsGeotag = self.post && self.post.blog.geolocationEnabled;
	if (isNewPost && postAllowsGeotag && [CLLocationManager locationServicesEnabled]) {
        self.isUpdatingLocation = YES;
        [self.locationManager startUpdatingLocation];
	}

    DDLogVerbose(@"Reloading map");
    self.geoView.address = self.address;
    self.geoView.coordinate = self.post.geolocation;

    if (self.address) {
        self.geoView.address = self.address;
    } else {
        self.geoView.address = NSLocalizedString(@"Finding address...", @"Used for Geo-tagging posts.");
        [self geocodeCoordinate:self.post.geolocation.coordinate];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.geoView = nil;
}

#pragma mark - CLLocationManager

- (CLLocationManager *)locationManager {
    if (self.locationManager) {
        return self.locationManager;
    }
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 10;
    return self.locationManager;
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	// If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
		if (!self.isUpdatingLocation) {
			return;
		}
		self.isUpdatingLocation = NO;
		CLLocationCoordinate2D coordinate = newLocation.coordinate;
#if FALSE // Switch this on/off for testing location updates
		// Factor values (YMMV)
		// 0.0001 ~> whithin your zip code (for testing small map changes)
		// 0.01 ~> nearby cities (good for testing address label changes)
		double factor = 0.001f;
		coordinate.latitude += factor * (rand() % 100);
		coordinate.longitude += factor * (rand() % 100);
#endif
		Coordinate *c = [[Coordinate alloc] initWithCoordinate:coordinate];
		self.post.geolocation = c;
        DDLogInfo(@"Added geotag (%+.6f, %+.6f)",
                  c.latitude,
                  c.longitude);
		[self.locationManager stopUpdatingLocation];
		
		[self geocodeCoordinate:c.coordinate];
        
    }
    // else skip the event and process the next one.
}

#pragma mark - CLGecocoder wrapper

- (void)geocodeCoordinate:(CLLocationCoordinate2D)c {
	if (self.reverseGeocoder) {
		if (self.reverseGeocoder.geocoding)
			[self.reverseGeocoder cancelGeocode];
	}
    self.reverseGeocoder = [[CLGeocoder alloc] init];
    [self.reverseGeocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:c.latitude longitude:c.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            if (placemark.subLocality) {
                self.address = [NSString stringWithFormat:@"%@, %@, %@", placemark.subLocality, placemark.locality, placemark.country];
            } else {
                self.address = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country];
            }
            self.geoView.address = self.address;
        } else {
            DDLogError(@"Reverse geocoder failed for coordinate (%.6f, %.6f): %@",
                       c.latitude,
                       c.longitude,
                       [error localizedDescription]);
            
            self.address = [NSString stringWithString:NSLocalizedString(@"Location unknown", @"Used when geo-tagging posts, if the geo-tagging failed.")];
            self.geoView.address = self.address;
        }
    }];
}

@end
