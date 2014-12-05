#import <UIKit/UIKit.h>

@interface WPMediaProgressTableViewController : UITableViewController

- (instancetype)initWithMasterProgress:(NSProgress *)masterProgress
             childrenProgress:(NSArray *)childrenProgress;

@end
