#import <UIKit/UIKit.h>
#import "PostCardActionBar.h"
#import "WPPostContentViewProvider.h"

@protocol PostCardTableViewCellDelegate;

@interface PostCardTableViewCell : UITableViewCell

@property (nonatomic, weak) id<PostCardTableViewCellDelegate>delegate;
@property (nonatomic, assign) BOOL canShowRestoreView;

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider;

@end


@protocol PostCardTableViewCellDelegate <NSObject>
@optional
- (void)cell:(PostCardTableViewCell *)cell receivedEditActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedViewActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedStatsActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedTrashActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedPublishActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedRestoreActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
@end
