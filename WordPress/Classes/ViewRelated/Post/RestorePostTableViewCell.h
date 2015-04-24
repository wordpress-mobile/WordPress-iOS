#import <UIKit/UIKit.h>
#import "WPPostContentViewProvider.h"
#import "PostCardTableViewCellDelegate.h"

@interface RestorePostTableViewCell : UITableViewCell

@property (nonatomic, weak) id<PostCardTableViewCellDelegate>delegate;

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider;

@end
