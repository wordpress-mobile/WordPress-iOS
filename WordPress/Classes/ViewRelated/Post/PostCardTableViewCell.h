#import <UIKit/UIKit.h>
#import "ConfigurablePostView.h"
#import "InteractivePostView.h"

@protocol ConfigurablePostView;
@protocol PostActionSheetDelegate;

@interface PostCardTableViewCell : UITableViewCell <ConfigurablePostView, InteractivePostView>
- (void)setActionSheetDelegate:(nonnull id<PostActionSheetDelegate>)delegate;
@end
