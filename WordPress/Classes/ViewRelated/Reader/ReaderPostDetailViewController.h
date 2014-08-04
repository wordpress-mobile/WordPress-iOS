#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong, readonly) ReaderPost *post;

+ (instancetype)postDetailsWithPost:(ReaderPost *)post;
+ (instancetype)postDetailsWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

@end
