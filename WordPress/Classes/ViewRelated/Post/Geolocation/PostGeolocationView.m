#import "PostGeolocationView.h"
#import "PostAnnotation.h"

const CGFloat DefaultLabelMargin = 20.0f;
const CGFloat GeoViewMinHeight = 130.0f;

@interface PostGeolocationView ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) PostAnnotation *annotation;

@end

@implementation PostGeolocationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        self.labelMargin = DefaultLabelMargin;
    }
    return self;
}

- (void)setupSubviews
{
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:self.mapView];

    CGFloat x = self.labelMargin;
    CGFloat w = self.frame.size.width - (2 * x);

    self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 130.0f, w, 60.0)];
    self.addressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.addressLabel.font = [WPStyleGuide regularTextFont];
    self.addressLabel.textColor = [WPStyleGuide allTAllShadeGrey];
    self.addressLabel.numberOfLines = 0;
    self.addressLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.addressLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat availableHeight = MAX(CGRectGetHeight(self.frame), GeoViewMinHeight);
    CGFloat addressLabelHeight = 80.0f;
    CGFloat mapHeight = availableHeight - addressLabelHeight;

    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat labelX = self.labelMargin;
    CGFloat labelWidth = CGRectGetWidth(self.frame) - (2 * labelX);

    self.mapView.frame = CGRectMake(0.0, 0.0, width, mapHeight);
    self.addressLabel.frame = CGRectMake(labelX, mapHeight, labelWidth, addressLabelHeight);
}

- (void)setAddress:(NSString *)address
{
    _address = address;
    [self updateAddressLabel];
}

- (void)setCoordinate:(Coordinate *)coordinate
{
    if ([coordinate isEqual:_coordinate]) {
        return;
    }

    _coordinate = coordinate;

    [self.mapView removeAnnotation:self.annotation];

    if (coordinate.latitude == 0 && coordinate.longitude == 0) {
        [self.mapView setRegion:MKCoordinateRegionForMapRect(MKMapRectWorld) animated:NO];
    } else {
        self.annotation = [[PostAnnotation alloc] initWithCoordinate:self.coordinate.coordinate];
        [self.mapView addAnnotation:self.annotation];

        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate.coordinate, 200, 100);
        [self.mapView setRegion:region animated:YES];
    }

    [self updateAddressLabel];
}

- (void)updateAddressLabel
{
    NSString *coordText = @"";
    CLLocationDegrees latitude = self.coordinate.latitude;
    CLLocationDegrees longitude = self.coordinate.longitude;

    if (latitude != 0 && longitude !=0 ) {
        NSInteger latD = trunc(fabs(latitude));
        NSInteger latM = trunc((fabs(latitude) - latD) * 60);
        NSInteger lonD = trunc(fabs(longitude));
        NSInteger lonM = trunc((fabs(longitude) - lonD) * 60);
        NSString *latDir = (latitude > 0) ? NSLocalizedString(@"North", @"Used for Geo-tagging posts by latitude and longitude. Basic form.") : NSLocalizedString(@"South", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
        NSString *lonDir = (longitude > 0) ? NSLocalizedString(@"East", @"Used for Geo-tagging posts by latitude and longitude. Basic form.") : NSLocalizedString(@"West", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
        if (latitude == 0.0) latDir = @"";
        if (longitude == 0.0) lonDir = @"";

        coordText = [NSString stringWithFormat:@"%i°%i' %@, %i°%i' %@",
                     latD, latM, latDir,
                     lonD, lonM, lonDir];
    }
    self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@", self.address, coordText];
}

- (BOOL)scrollEnabled
{
    return self.mapView.scrollEnabled;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    self.mapView.scrollEnabled = scrollEnabled;
}

@end
