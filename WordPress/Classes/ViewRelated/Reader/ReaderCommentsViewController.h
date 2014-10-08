#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderCommentsViewController : UITableViewController

@property (nonatomic, strong, readonly) ReaderPost *post;

+ (instancetype)controllerWithPost:(ReaderPost *)post;

@end
