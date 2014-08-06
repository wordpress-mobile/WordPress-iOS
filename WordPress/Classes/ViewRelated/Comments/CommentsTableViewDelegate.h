#import <UIKit/UIKit.h>

@protocol CommentsTableViewDelegate<UITableViewDelegate>
- (void)tableView : (UITableView *)tableView didCheckRowAtIndexPath : (NSIndexPath *)indexPath;
@end
