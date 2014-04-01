#import "WPTableViewCell.h"
#import "Coordinate.h"

@interface PostGeolocationCell : WPTableViewCell

- (void)setCoordinate:(Coordinate *)coordinate andAddress:(NSString *)address;

@end
