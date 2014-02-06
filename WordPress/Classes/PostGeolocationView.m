//
//  PostGeolocationView.m
//  WordPress
//
//  Created by Eric Johnson on 1/23/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostGeolocationView.h"
#import "PostAnnotation.h"

const CGFloat LabelMargins = 20.0f;

@interface PostGeolocationView ()

@property (nonatomic, strong) PostAnnotation *annotation;

@end

@implementation PostGeolocationView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.mapView];
    
    CGFloat x = LabelMargins;
    CGFloat w = self.frame.size.width - (2 * x);
    
    self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 130.0f, w, 30.0)];
    self.addressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.addressLabel.font = [WPStyleGuide regularTextFont];
    self.addressLabel.textColor = [WPStyleGuide allTAllShadeGrey];
    [self addSubview:self.addressLabel];
    
    self.coordinateLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 162.0f, w, 20.0f)];
    self.coordinateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.coordinateLabel.font = [WPStyleGuide regularTextFont];
    self.coordinateLabel.textColor = [WPStyleGuide allTAllShadeGrey];
    [self addSubview:self.coordinateLabel];
}

- (NSString *)address {
    return self.addressLabel.text;
}

- (void)setAddress:(NSString *)address {
    self.addressLabel.text = address;
}

- (void)setCoordinate:(Coordinate *)coordinate {
    _coordinate = coordinate;
    
    [self.mapView removeAnnotation:self.annotation];
    self.annotation = [[PostAnnotation alloc] initWithCoordinate:self.coordinate.coordinate];
    [self.mapView addAnnotation:self.annotation];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate.coordinate, 200, 100);
    [self.mapView setRegion:region animated:YES];
    
    CLLocationDegrees latitude = coordinate.latitude;
    CLLocationDegrees longitude = coordinate.longitude;
    int latD = trunc(fabs(latitude));
    int latM = trunc((fabs(latitude) - latD) * 60);
    int lonD = trunc(fabs(longitude));
    int lonM = trunc((fabs(longitude) - lonD) * 60);
    NSString *latDir = (latitude > 0) ? NSLocalizedString(@"North", @"Used for Geo-tagging posts by latitude and longitude. Basic form.") : NSLocalizedString(@"South", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
    NSString *lonDir = (longitude > 0) ? NSLocalizedString(@"East", @"Used for Geo-tagging posts by latitude and longitude. Basic form.") : NSLocalizedString(@"West", @"Used for Geo-tagging posts by latitude and longitude. Basic form.");
    if (latitude == 0.0) latDir = @"";
    if (longitude == 0.0) lonDir = @"";
    
    self.coordinateLabel.text = [NSString stringWithFormat:@"%i°%i' %@, %i°%i' %@",
                                 latD, latM, latDir,
                                 lonD, lonM, lonDir];
}

@end
