//
//  PostGeolocationCell.m
//  WordPress
//
//  Created by Eric Johnson on 1/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostGeolocationCell.h"
#import <MapKit/MapKit.h>

@interface PostGeolocationCell ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *coordinateLabel;

@end

@implementation PostGeolocationCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        self.addressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.coordinateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    return self;
}



@end
