#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "ReaderPostView.h"
#import "ReaderCommentTableViewCell.h"

@interface ReaderPostDetailViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ReaderPostViewDelegate, ReaderCommentTableViewCellDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) NSURL *avatarImageURL;
@property (nonatomic, assign) BOOL showInlineActionBar;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (id)initWithPost:(ReaderPost *)post avatarImageURL:(NSURL *)avatarImageURL;

- (void)updateFeaturedImage:(UIImage *)image;

@end
