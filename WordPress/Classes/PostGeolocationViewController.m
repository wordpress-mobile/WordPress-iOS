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
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;

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
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupToolbar];
    
    self.geoView = [[PostGeolocationView alloc] initWithFrame:self.view.bounds];
    self.geoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if (self.post.geolocation) {
        self.geoView.address = [LocationService sharedService].lastGeocodedAddress;
        self.geoView.coordinate = self.post.geolocation;
    }
    
    [self.view addSubview:self.geoView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    
    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }
}

#pragma mark - Appearance Related Methods

- (void)setupToolbar {
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.translucent = NO;
    toolbar.barStyle = UIBarStyleDefault;
    
    if ([self.toolbarItems count] > 0) {
        return;
    }
    
    self.deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-comments-trash"] style:UIBarButtonItemStylePlain target:self action:@selector(removeGeolocation)];
    self.refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sync_lite"] style:UIBarButtonItemStylePlain target:self action:@selector(updateLocation)];
    
    self.deleteButton.tintColor = [WPStyleGuide readGrey];
    self.refreshButton.tintColor = [WPStyleGuide readGrey];
    
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;
    
    self.toolbarItems = @[leftFixedSpacer, self.deleteButton, centerFlexSpacer, self.refreshButton, rightFixedSpacer];
}


- (void)removeGeolocation {
    self.post.geolocation = nil;
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)updateLocation {
    [[LocationService sharedService] getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
        
        if (location) {
            Coordinate *coord = [[Coordinate alloc] initWithCoordinate:location.coordinate];
            self.post.geolocation = coord;
            [self.geoView setCoordinate:coord];
            [self.geoView setAddress:address];
        }
        
    }];
}

/*
 NSDate* eventDate = newLocation.timestamp;
 NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
 if (abs(howRecent) < 15.0)
 */


@end
