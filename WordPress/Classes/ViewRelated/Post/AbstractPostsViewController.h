#import "WPTableViewController.h"

@class AbstractPostTableViewCell;
@class BasePost;
@class WPTableImageSource;

@interface AbstractPostsViewController : WPTableViewController

@property (nonatomic, strong) AbstractPostTableViewCell *cellForLayout;
@property (nonatomic, strong) WPTableImageSource *featuredImageSource;
@property (nonatomic, strong) NSMutableDictionary *cachedRowHeights;

- (void)setImageForPost:(BasePost *)post forCell:(AbstractPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath;

@end
