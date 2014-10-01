#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong, readonly) ReaderPost *post;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)detailControllerWithPost:(ReaderPost *)post;
+ (instancetype)detailControllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

@end
