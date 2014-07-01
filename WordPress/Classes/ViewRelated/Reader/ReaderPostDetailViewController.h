#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong) ReaderPost *post;

- (instancetype)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (instancetype)initWithPost:(ReaderPost *)post avatarImageURL:(NSURL *)avatarImageURL;
- (void)updateFeaturedImage:(UIImage *)image;

@end
