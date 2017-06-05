#import "Coordinate.h"
#import <WordPressShared/WPTableViewCell.h>

@interface PostGeolocationCell : WPTableViewCell

- (void)setCoordinate:(Coordinate *)coordinate andAddress:(NSString *)address;

@end
