#import <UIKit/UIKit.h>

@class Post;
@class LocationService;

@protocol PostGeolocationViewControllerDelegate <NSObject>
- (void)postGeolocationViewControllerClosed;
@end

@interface PostGeolocationViewController : UIViewController

- (id)initWithPost:(Post *)post locationService:(LocationService *)locationService;

@property (nonatomic, weak) id <PostGeolocationViewControllerDelegate> delegate;
@property (nonatomic, assign) bool isRemoveVisible;

@end
