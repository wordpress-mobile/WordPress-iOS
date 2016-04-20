#import <UIKit/UIKit.h>

@class Post;
@class LocationService;

@interface PostGeolocationViewController : UIViewController

- (id)initWithPost:(Post *)post locationService:(LocationService *)locationService;

@end
