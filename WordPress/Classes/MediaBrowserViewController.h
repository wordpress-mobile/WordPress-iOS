#import <UIKit/UIKit.h>
#import "MediaSearchFilterHeaderView.h"

// Notifications
extern NSString *const MediaFeaturedImageSelectedNotification;
extern NSString *const MediaShouldInsertBelowNotification;
@class Blog, AbstractPost;

@interface MediaBrowserViewController : UIViewController <MediaSearchFilterDelegate, UISearchBarDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) Blog *blog;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (id)initWithPost:(AbstractPost *)post;
- (id)initWithPost:(AbstractPost *)post selectingMediaForPost:(BOOL)selectingMediaForPost;
- (id)initWithPost:(AbstractPost *)post selectingFeaturedImage:(BOOL)selectingFeaturedImage;

@end
