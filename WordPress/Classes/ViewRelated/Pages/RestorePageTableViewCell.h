#import <UIKit/UIKit.h>
#import "PageListTableViewCellDelegate.h"

@interface RestorePageTableViewCell : UITableViewCell

@property (nonatomic, assign, readwrite, nullable) id<PageListTableViewCellDelegate> delegate;

- (void)configureCell:(nonnull id<WPPostContentViewProvider>)contentProvider;

@end
