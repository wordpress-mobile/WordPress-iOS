//
//  PostGeolocationCell.m
//  WordPress
//
//  Created by Eric Johnson on 1/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostGeolocationCell.h"
#import <MapKit/MapKit.h>

#import "PostGeolocationView.h"

@interface PostGeolocationCell ()

@property (nonatomic, strong) PostGeolocationView *geoView;

@end

@implementation PostGeolocationCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createSubviews];
    }
    return self;
}

- (void)createSubviews {
    self.geoView = [[PostGeolocationView alloc] initWithFrame:self.contentView.bounds];
    self.geoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.geoView];
}

- (void)setCoordinate:(Coordinate *)coordinate andAddress:(NSString *)address {
    self.geoView.coordinate = coordinate;
    self.geoView.address = address;
}

@end
