#import "MenuItemSourceResultsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MenuItemAbstractPostsViewController : MenuItemSourceResultsViewController

@end

@class PostServiceSyncOptions;

@protocol MenuItemSourcePostAbstractViewSubclass <NSObject>
- (Class)entityClass;
- (PostServiceSyncOptions *)syncOptions;
@end

NS_ASSUME_NONNULL_END
