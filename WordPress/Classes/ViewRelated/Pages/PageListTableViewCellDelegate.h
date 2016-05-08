#import "WPPostContentViewProvider.h"
@protocol PageListTableViewCellDelegate <NSObject>
@optional
- (void)cell:(UITableViewCell *)cell receivedMenuActionFromButton:(UIButton *)button forProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedRestoreActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
@end