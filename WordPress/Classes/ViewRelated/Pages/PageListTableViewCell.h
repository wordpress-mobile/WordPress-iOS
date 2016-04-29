#import <UIKit/UIKit.h>
#import "PageListTableViewCellDelegate.h"

@interface PageListTableViewCell : UITableViewCell

@property (nonatomic, assign, readwrite, nullable) id<PageListTableViewCellDelegate> delegate;

- (void)configureCell:(nonnull id<WPPostContentViewProvider>)contentProvider;

@end
