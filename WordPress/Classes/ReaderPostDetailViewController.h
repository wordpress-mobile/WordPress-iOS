#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "ReaderPostView.h"
#import "ReaderCommentTableViewCell.h"

@interface ReaderPostDetailViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ReaderPostViewDelegate, ReaderCommentTableViewCellDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, assign) BOOL showInlineActionBar;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (void)updateFeaturedImage:(UIImage *)image;

@end
