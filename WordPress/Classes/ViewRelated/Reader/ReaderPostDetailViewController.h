#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UITableViewController

@property (nonatomic, strong) ReaderPost *post;

- (instancetype)initWithPost:(ReaderPost *)post;

@end
