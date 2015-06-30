#import "WPPostContentViewProvider.h"

@protocol PostCardTableViewCellDelegate <NSObject>
@optional
- (void)cell:(UITableViewCell *)cell receivedEditActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedViewActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedStatsActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedTrashActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedPublishActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(UITableViewCell *)cell receivedRestoreActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
@end