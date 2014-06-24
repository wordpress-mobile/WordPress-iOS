#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, assign) BOOL showInlineActionBar;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (id)initWithPost:(ReaderPost *)post avatarImageURL:(NSURL *)avatarImageURL;
- (void)updateFeaturedImage:(UIImage *)image;

@end
