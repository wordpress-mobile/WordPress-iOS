#import "PostGeolocationViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "LocationService.h"
#import "Post.h"
#import "PostAnnotation.h"
#import "PostGeolocationView.h"
#import "WPTableViewCell.h"
#import "WordPress-Swift.h"

static NSString *CLPlacemarkTableViewCellIdentifier = @"CLPlacemarkTableViewCellIdentifier";

@interface PostGeolocationViewController () <MKMapViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostGeolocationView *geoView;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *activityItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) LocationService *locationService;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<CLPlacemark *> *placemarks;

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
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = NSLocalizedString(@"Search", @"Prompt in the location search bar.");
    self.searchBar.delegate = self;
    [self.view addSubview:self.searchBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.geoView.frame style:UITableViewStylePlain];
    self.tableView.hidden = YES;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CLPlacemarkTableViewCellIdentifier];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.searchBar.frame = CGRectMake(0, [self.topLayoutGuide length], self.view.frame.size.width, 44);
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.searchBar.frame), self.view.frame.size.width, self.view.frame.size.height-CGRectGetMaxY(self.searchBar.frame));
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
        UIImage *image = [[UIImage imageNamed:@"gridicons-location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
    
    if ([self.locationService locationServicesDisabled] || [self.locationService locationServicesDenied]) {
        [self.locationService showAlertForLocationServicesDisabled];
        return;
    }

    [self.locationService getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
        if (error) {
            [self refreshView];
            [self.locationService showAlertForLocationError:error];
            return;
        }
        if (location) {
            Coordinate *coord = [[Coordinate alloc] initWithCoordinate:location.coordinate];
            self.post.geolocation = coord;
            [self refreshView];
        }
    }];

    [self refreshView];
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

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSString *query = searchText;
    if (query.length < 5) {
        return;
    }
    self.searchBar.showsCancelButton = YES;
    self.tableView.hidden = NO;
    __weak __typeof__(self) weakSelf = self;
    [self.locationService searchPlacemarksWithQuery:query completion:^(NSArray *placemarks, NSError *error) {
        if (error) {
            return;
        }
        [weakSelf showSearchResults:placemarks];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.tableView.hidden = YES;
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
}

- (void)showSearchResults:(NSArray<CLPlacemark *> *)placemarks
{
    self.placemarks = placemarks;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.placemarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CLPlacemarkTableViewCellIdentifier forIndexPath:indexPath];
    CLPlacemark *placemark = self.placemarks[indexPath.row];
    cell.textLabel.text = placemark.name;
    cell.detailTextLabel.text = placemark.country;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLPlacemark *placemark = self.placemarks[indexPath.row];

    self.tableView.hidden = YES;
    self.searchBar.showsCancelButton = NO;
    Coordinate *coordinate = [[Coordinate alloc] initWithCoordinate:placemark.location.coordinate];
    CLRegion *placemarkRegion = placemark.region;
    if ([placemarkRegion isKindOfClass:[CLCircularRegion class]]) {
        CLCircularRegion *circularRegion = (CLCircularRegion *)placemarkRegion;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(circularRegion.center, circularRegion.radius, circularRegion.radius);
        [self.geoView setCoordinate:coordinate region:region];
    } else {
        [self.geoView setCoordinate:coordinate];
    }
    self.geoView.address = placemark.name;
    self.post.geolocation = self.geoView.coordinate;
}

@end
