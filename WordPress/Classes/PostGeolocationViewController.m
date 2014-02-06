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

#import "LocationService.h"
#import "Post.h"
#import "PostAnnotation.h"
#import "PostGeolocationView.h"

@interface PostGeolocationViewController () <MKMapViewDelegate>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostGeolocationView *geoView;

@end

@implementation PostGeolocationViewController

- (id)initWithPost:(Post *)post {
    self = [super init];
    if (self) {
        self.post = post;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.geoView = [[PostGeolocationView alloc] initWithFrame:self.view.bounds];
    self.geoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.geoView.address = [LocationService sharedService].lastGeocodedAddress;
    self.geoView.coordinate = self.post.geolocation;

    [self.view addSubview:self.geoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.geoView = nil;
}

/*
 NSDate* eventDate = newLocation.timestamp;
 NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
 if (abs(howRecent) < 15.0)
 */


@end
