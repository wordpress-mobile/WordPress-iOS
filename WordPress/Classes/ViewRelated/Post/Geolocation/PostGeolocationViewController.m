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

typedef NS_ENUM(NSInteger, SearchResultsSection) {
    SearchResultsSectionCurrentLocation = 0,
    SearchResultsSectionSearchResults = 1
};

@interface PostGeolocationViewController () <MKMapViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostGeolocationView *geoView;
@property (nonatomic, strong) UITableViewCell *currentLocationCell;
@property (nonatomic, strong) UIBarButtonItem *removeButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) LocationService *locationService;
@property (nonatomic, strong) UIView *searchBarTop;
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
    self.navigationItem.leftBarButtonItems = @[self.doneButton];
    self.navigationItem.rightBarButtonItems = @[self.removeButton];
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.searchBarTop];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.searchBarTop.hidden = !self.navigationController.navigationBarHidden;
    self.searchBarTop.frame = [[UIApplication sharedApplication] statusBarFrame];
    self.searchBar.frame = CGRectMake(0.0, [self.topLayoutGuide length]-1, self.view.frame.size.width, 44.0);
    self.tableView.frame = CGRectMake(0.0, CGRectGetMaxY(self.searchBar.frame), self.view.frame.size.width, self.view.frame.size.height-CGRectGetMaxY(self.searchBar.frame));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.post.geolocation) {
        [self refreshView];
    } else {
        [self searchCurrentLocationFromUserRequest:NO];
    }
}

- (UIView *)searchBarTop
{
    if (_searchBarTop == nil) {
        _searchBarTop = [[UIView alloc] init];
        _searchBarTop.backgroundColor = [WPStyleGuide wordPressBlue];
    }
    return _searchBarTop;
}

#pragma mark - View Properties

- (UISearchBar *)searchBar
{
    if (_searchBar == nil) {
        NSAttributedString *placeholderString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Search Locations", @"Prompt in the location search bar.") attributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide grey]]];
        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class], [PostGeolocationViewController class]]] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide darkGrey]]];
        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class], [PostGeolocationViewController class]]] setAttributedPlaceholder:placeholderString];
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.barTintColor = [WPStyleGuide greyLighten30];
        _searchBar.tintColor = [WPStyleGuide grey];
        UIImage *clearImage = [[UIImage imageNamed:@"icon-clear-searchfield"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_searchBar setImage:clearImage forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
        UIImage *searchImage = [[UIImage imageNamed:@"icon-post-list-search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_searchBar setImage:searchImage forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
        _searchBar.accessibilityIdentifier = @"Search";
    }
    return _searchBar;
}

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.geoView.frame style:UITableViewStylePlain];
        _tableView.hidden = YES;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CLPlacemarkTableViewCellIdentifier];
        _tableView.delegate = self;
        _tableView.rowHeight = 60.0;
        UIVisualEffectView *visualEffect = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        _tableView.backgroundView = visualEffect;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (UIBarButtonItem *)doneButton
{
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Label for confirm location of a post")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(confirmGeolocation)];
    }
    return _doneButton;
}


- (UIBarButtonItem *)removeButton
{
    if (!_removeButton) {
        _removeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Remove", @"Label for remove location button")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(removeGeolocation)];
    }
    return _removeButton;
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
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)confirmGeolocation
{
    self.post.geolocation = self.geoView.coordinate;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchCurrentLocationFromUserRequest:(BOOL)userRequest
{
    if ([self.locationService locationServicesDisabled] || [self.locationService locationServicesDenied]) {
        if (userRequest) {
            [self.locationService showAlertForLocationServicesDisabled];
        }
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    [self.locationService getCurrentLocationAndAddress:^(CLLocation *location, NSString *address, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __typeof__(weakSelf) strongSelf = weakSelf;
            if (error) {
                [strongSelf refreshView];
                if (userRequest) {
                    [strongSelf.locationService showAlertForLocationError:error];
                }
                return;
            }
            if (location) {
                Coordinate *coord = [[Coordinate alloc] initWithCoordinate:location.coordinate];
                strongSelf.post.geolocation = coord;
                [strongSelf refreshView];
            }
        });
    }];

    [self refreshView];
}

- (void)refreshView
{
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

- (void)enableSearch:(BOOL)searchOn
{
    self.searchBar.showsCancelButton = searchOn;
    [self.navigationController setNavigationBarHidden:searchOn animated:YES];
    self.searchBar.translucent = NO;
    self.tableView.hidden = !searchOn;
    _searchBar.barTintColor = searchOn ? [WPStyleGuide wordPressBlue]:[WPStyleGuide greyLighten30];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self enableSearch:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSString *query = searchText;
    if (query.length < 3) {
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    [self.locationService searchPlacemarksWithQuery:query completion:^(NSArray *placemarks, NSError *error) {
        if (error) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showSearchResults:placemarks];
        });
        
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self enableSearch:NO];
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SearchResultsSectionCurrentLocation:
            return 1;
        case SearchResultsSectionSearchResults:
            return self.placemarks.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SearchResultsSectionCurrentLocation:
            return self.currentLocationCell;
        case SearchResultsSectionSearchResults: {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CLPlacemarkTableViewCellIdentifier forIndexPath:indexPath];
            CLPlacemark *placemark = self.placemarks[indexPath.row];
            cell.textLabel.text = placemark.formattedAddress;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.font = [WPStyleGuide regularTextFont];
            cell.textLabel.textColor = [WPStyleGuide darkGrey];
            cell.backgroundColor = [UIColor clearColor];
            cell.selected = NO;
            return cell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self enableSearch:NO];
    [self.searchBar resignFirstResponder];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case SearchResultsSectionCurrentLocation:
            [self searchCurrentLocationFromUserRequest:YES];
            break;
        case SearchResultsSectionSearchResults: {
            CLPlacemark *placemark = self.placemarks[indexPath.row];
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
            break;
    }
    
}

- (UITableViewCell *)currentLocationCell {
    if (_currentLocationCell == nil) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        UIImage *image = [[UIImage imageNamed:@"gridicons-location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = NSLocalizedString(@"Use Current Location", @"Label for cell that sets the location of a post to the current location");
        cell.imageView.image = image;
        cell.imageView.tintColor = [WPStyleGuide mediumBlue];
        cell.textLabel.font = [WPStyleGuide regularTextFont];
        cell.textLabel.textColor = [WPStyleGuide darkGrey];
        cell.backgroundColor = [UIColor clearColor];
        _currentLocationCell = cell;
    }
    _currentLocationCell.selected = NO;
    return _currentLocationCell;
}

#pragma mark - Status bar management

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

@end
