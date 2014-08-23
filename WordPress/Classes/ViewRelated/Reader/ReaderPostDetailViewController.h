#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong) ReaderPost *post;

- (instancetype)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (void)updateFeaturedImage:(UIImage *)image;

@end
