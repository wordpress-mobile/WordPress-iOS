#import "PostGeolocationViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "LocationService.h"
#import "Post.h"
#import "PostAnnotation.h"
#import "PostGeolocationView.h"
#import "WPTableViewCell.h"

@interface PostGeolocationViewController () <MKMapViewDelegate>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostGeolocationView *geoView;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *activityItem;

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
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    [self setupToolbar];

    CGRect frame = self.view.bounds;
    UIViewAutoresizing mask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    if (IS_IPAD) {
        mask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        frame.size.width = WPTableViewFixedWidth;
        frame.origin.x = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(frame)) / 2;
    }
    self.geoView = [[PostGeolocationView alloc] initWithFrame:frame];
    self.geoView.autoresizingMask = mask;
    self.geoView.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.geoView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }

    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }

    if (self.post.geolocation) {
        [self refreshView];
    } else {
        [self updateLocation];
    }
}

#pragma mark - Appearance Related Methods

- (void)setupToolbar
{
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

    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityView startAnimating];
    self.activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
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

    if (![self.post.blog geolocationEnabled]) {
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
    [self refreshToolbar];

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

- (void)refreshToolbar
{
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;

    if ([[LocationService sharedService] locationServiceRunning]) {
        self.toolbarItems = @[leftFixedSpacer, self.deleteButton, centerFlexSpacer, self.activityItem, rightFixedSpacer];
    } else {
        self.toolbarItems = @[leftFixedSpacer, self.deleteButton, centerFlexSpacer, self.refreshButton, rightFixedSpacer];
    }
}

@end
