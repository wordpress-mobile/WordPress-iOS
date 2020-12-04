#import "Coordinate.h"

@implementation Coordinate
@synthesize coordinate = _coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self = [super init]) {
        _coordinate = coordinate;
    }
    return self;
}

- (CLLocationDegrees)latitude
{
    return _coordinate.latitude;
}

- (CLLocationDegrees)longitude
{
    return _coordinate.longitude;
}

#pragma mark -
#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:@(_coordinate.latitude) forKey:@"latitude"];
    [encoder encodeObject:@(_coordinate.longitude) forKey:@"longitude"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _coordinate.latitude = [[decoder decodeObjectOfClass:[NSNumber class] forKey:@"latitude"] doubleValue];
        _coordinate.longitude = [[decoder decodeObjectOfClass:[NSNumber class] forKey:@"longitude"] doubleValue];
    }

    return self;
}

@end
