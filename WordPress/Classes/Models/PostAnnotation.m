#import "PostAnnotation.h"

@implementation PostAnnotation
@synthesize coordinate = _coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D) c
{
    self = [super init];
    if (self != nil) {
        _coordinate = c;
    }
    return self;
}

@end
