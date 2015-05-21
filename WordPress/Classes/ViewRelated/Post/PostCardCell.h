#import "WPPostContentViewProvider.h"
#import "PostCardTableViewCellDelegate.h"

@protocol PostCardCell <NSObject>

@property (nonatomic, weak) id<PostCardTableViewCellDelegate>delegate;

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider;

@end
