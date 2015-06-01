#import "WPContentViewProvider.h"
#import "PageListTableViewCellDelegate.h"

@protocol PageListCell <NSObject>

@property (nonatomic, weak) id<PageListTableViewCellDelegate>delegate;

- (void)configureCell:(id<WPContentViewProvider>)contentProvider;

@end
