//
//  Coordinate.m
//  WordPress
//
//  Created by Jorge Bernal on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "Coordinate.h"


@implementation Coordinate
@synthesize coordinate = _coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c {
	if (self = [super init]) {
		_coordinate = c;
	}
	return self;
}

- (CLLocationDegrees)latitude {
	return _coordinate.latitude;
}

- (CLLocationDegrees)longitude {
	return _coordinate.longitude;
}

#pragma mark -
#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeDouble:_coordinate.latitude forKey:@"latitude"];
	[encoder encodeDouble:_coordinate.longitude forKey:@"longitude"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		_coordinate.latitude = [decoder decodeDoubleForKey:@"latitude"];
		_coordinate.longitude = [decoder decodeDoubleForKey:@"longitude"];
	}
	
	return self;
}

@end
