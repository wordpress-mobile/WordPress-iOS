#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Coordinate : NSObject <NSCoding> {
    CLLocationCoordinate2D _coordinate;
}

@property (readonly) CLLocationDegrees latitude;
@property (readonly) CLLocationDegrees longitude;
@property (assign) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end
