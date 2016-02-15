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
@property (nonatomic, strong) LocationService *locationService;

@end

@implementation PostGeolocationViewController

- (id)initWithPost:(Post *)post locationService:(LocationService *)locationService
{
    self = [super init];
    if (self) {
        _post = post;
        _locationService = locationService;
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

- (UIBarButtonItem *)refreshButton
{
    if (!_refreshButton) {
        UIImage *image = [[UIImage imageNamed:@"gridicons-sync"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _refreshButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(updateLocation)];
    }
    return _refreshButton;
}

- (UIBarButtonItem *)activityItem
{
    if (!_activityItem) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityItem = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];
    }
    return _activityItem;
}

- (PostGeolocationView *)geoView
{
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
    if ([self.locationService locationServicesDisabled]) {
        [self showLocationPermissionDisabled];
        return;
    }

    if (!self.post.blog.settings.geolocationEnabled) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Enable Geotagging", @"Title of an alert view stating the user needs to turn on geotagging.")
                            message:NSLocalizedString(@"Geotagging is turned off. \nTo update this post's location, please enable geotagging in this site's settings.", @"Message of an alert explaining that geotagging need to be enabled.")
                  withSupportButton:NO];
        return;
    }

    [self.locationService getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
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

- (void)showLocationPermissionDisabled
{
    [self showLocationError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil]];
}

- (void)showLocationError:(NSError *)error
{
    NSString *title = NSLocalizedString(@"Location", @"Title for alert when a generic error happened when trying to find the location of the device");
    NSString *message = NSLocalizedString(@"There was a problem when trying to access your location. Please try again later.",  @"Explaining to the user there was an error trying to obtain the current location of the user.");
    NSString *cancelText = NSLocalizedString(@"OK", "");
    NSString *otherButtonTitle = nil;
    if (error.domain == kCLErrorDomain && error.code == kCLErrorDenied) {
        otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
        title = NSLocalizedString(@"Location", @"Title for alert when access to the media library is not granted by the user");
        message = NSLocalizedString(@"WordPress needs permission to access your device location in order to geotag your post. Please change the privacy settings if you wish to allow this.",  @"Explaining to the user why the app needs access to the device location.");
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
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)refreshView
{
    [self refreshNavigationBar];

    if ([self.locationService locationServiceRunning]) {
        self.geoView.coordinate = nil;
        self.geoView.address = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");

    } else if (self.post.geolocation) {
        self.geoView.coordinate = self.post.geolocation;
        self.geoView.address = [self.locationService lastGeocodedAddress];

    } else {
        self.geoView.coordinate = nil;
        self.geoView.address = [self.locationService lastGeocodedAddress];
    }
}

- (void)refreshNavigationBar
{
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;

    if ([self.locationService locationServiceRunning]) {
        self.navigationItem.rightBarButtonItems = @[leftFixedSpacer, self.activityItem, rightFixedSpacer];
        [self.activityIndicator startAnimating];
    } else {
        self.navigationItem.rightBarButtonItems = @[leftFixedSpacer, self.refreshButton, rightFixedSpacer];
    }
}

@end
