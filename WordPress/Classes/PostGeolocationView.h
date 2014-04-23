#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Coordinate.h"

@interface PostGeolocationView : UIView

@property (nonatomic, strong) Coordinate *coordinate;
@property (nonatomic, strong) NSString *address;
@property (nonatomic) CGFloat labelMargin;
@property (nonatomic) BOOL scrollEnabled;

@end
