#import "WPTableViewController.h"
#import "WPTableImageSource.h"

@class AbstractPostTableViewCell;
@class BasePost;

@interface AbstractPostsViewController : WPTableViewController <WPTableImageSourceDelegate>

@property (nonatomic, strong) AbstractPostTableViewCell *cellForLayout;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) NSMutableDictionary *cachedRowHeights;

- (void)setImageForPost:(BasePost *)post forCell:(AbstractPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath;

@end
