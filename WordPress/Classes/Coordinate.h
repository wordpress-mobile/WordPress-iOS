//
//  Coordinate.h
//  WordPress
//
//  Created by Jorge Bernal on 2/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Coordinate : NSObject <NSCoding> {
	CLLocationCoordinate2D _coordinate;
}
- (id)initWithCoordinate:(CLLocationCoordinate2D)c;
@property (readonly) CLLocationDegrees latitude;
@property (readonly) CLLocationDegrees longitude;
@property (assign) CLLocationCoordinate2D coordinate;

@end
