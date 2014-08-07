#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong, readonly) ReaderPost *post;

+ (instancetype)detailControllerWithPost:(ReaderPost *)post;
+ (instancetype)detailControllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

@end
