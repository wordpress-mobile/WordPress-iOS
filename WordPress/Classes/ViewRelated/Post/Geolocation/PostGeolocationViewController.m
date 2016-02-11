#import "PostGeolocationViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "LocationService.h"
#import "Post.h"
#import "PostAnnotation.h"
#import "PostGeolocationView.h"
#import "WPTableViewCell.h"
#import "WordPress-Swift.h"

@interface PostGeolocationViewController () <MKMapViewDelegate>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostGeolocationView *geoView;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *activityItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation PostGeolocationViewController

- (id)initWithPost:(Post *)post
{
    self = [super init];
    if (self) {
        self.post = post;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [WPStyleGuide greyLighten30];
    self.title = NSLocalizedString(@"Location", @"Title for screen to select post location");
    [self.view addSubview:self.geoView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.post.geolocation) {
        [self refreshView];
    } else {
        [self updateLocation];
    }
}

#pragma mark - Appearance Related Methods

- (UIBarButtonItem *)refreshButton {
    if (!_refreshButton) {
        UIImage *image = [[UIImage imageNamed:@"gridicons-sync"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _refreshButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(updateLocation)];
    }
    return _refreshButton;
}

- (UIBarButtonItem *)activityItem {
    if (!_activityItem) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityItem = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];
    }
    return _activityItem;
}

- (PostGeolocationView *)geoView {
    if (!_geoView) {
        CGRect frame = self.view.bounds;
        UIViewAutoresizing mask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _geoView = [[PostGeolocationView alloc] initWithFrame:frame];
        _geoView.autoresizingMask = mask;
        _geoView.backgroundColor = [UIColor whiteColor];
    }
    return _geoView;
}

- (void)removeGeolocation
{
    self.post.geolocation = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateLocation
{
    if ([[LocationService sharedService] locationServicesDisabled]) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Location Unavailable", @"Title of an alert view stating that the user's location is unavailable.")
                            message:NSLocalizedString(@"Location Services are turned off. \nTo add or update this post's location, please enable Location Services in the Settings app.", @"Message of an alert explaining that location services need to be enabled.")
                  withSupportButton:NO];
        return;
    }

    if (!self.post.blog.settings.geolocationEnabled) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Enable Geotagging", @"Title of an alert view stating the user needs to turn on geotagging.")
                            message:NSLocalizedString(@"Geotagging is turned off. \nTo update this post's location, please enable geotagging in this site's settings.", @"Message of an alert explaining that geotagging need to be enabled.")
                  withSupportButton:NO];
        return;
    }

    [[LocationService sharedService] getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
        if (location) {
            Coordinate *coord = [[Coordinate alloc] initWithCoordinate:location.coordinate];
            self.post.geolocation = coord;
            [self refreshView];
        } else if (error) {
            [self refreshView];
            NSString *message = NSLocalizedString(@"There was a problem finding your current location.", @"Generic message explaining there was a problem finding the user's current location.");
            message = [NSString stringWithFormat:@"%@ %@", message, [error localizedDescription]];
            [WPError showAlertWithTitle:NSLocalizedString(@"Location Unavailable", @"Title of an alert view stating that the user's location is unavailable.")
                                message:message
                      withSupportButton:NO];
        }
    }];

    [self refreshView];
}

- (void)refreshView
{
    [self refreshNavigationBar];

    if ([[LocationService sharedService] locationServiceRunning]) {
        self.geoView.coordinate = nil;
        self.geoView.address = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");

    } else if (self.post.geolocation) {
        self.geoView.coordinate = self.post.geolocation;
        self.geoView.address = [[LocationService sharedService] lastGeocodedAddress];

    } else {
        self.geoView.coordinate = nil;
        self.geoView.address = [[LocationService sharedService] lastGeocodedAddress];
    }
}

- (void)refreshNavigationBar
{
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;

    if ([[LocationService sharedService] locationServiceRunning]) {
        self.navigationItem.rightBarButtonItems = @[leftFixedSpacer, self.activityItem, rightFixedSpacer];
        [self.activityIndicator startAnimating];
    } else {
        self.navigationItem.rightBarButtonItems = @[leftFixedSpacer, self.refreshButton, rightFixedSpacer];
    }
}

@end
