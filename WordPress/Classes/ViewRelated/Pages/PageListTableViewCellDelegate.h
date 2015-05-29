#import "WPContentViewProvider.h"
@protocol PageListTableViewCellDelegate <NSObject>
@optional
- (void)cell:(UITableViewCell *)cell receivedMenuActionFromButton:(UIButton *)button forProvider:(id<WPContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedRestoreActionForProvider:(id<WPContentViewProvider>)contentProvider;
@end