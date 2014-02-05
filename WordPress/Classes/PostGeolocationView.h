//
//  PostGeolocationView.h
//  WordPress
//
//  Created by Eric Johnson on 1/23/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Coordinate.h"

@interface PostGeolocationView : UIView

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *coordinateLabel;
@property (nonatomic, strong) Coordinate *coordinate;
@property (nonatomic, weak) NSString *address;

@end
