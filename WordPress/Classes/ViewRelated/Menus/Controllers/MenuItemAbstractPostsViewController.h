#import "MenuItemSourceResultsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MenuItemAbstractPostsViewController : MenuItemSourceResultsViewController

@end

@class MenuPostServiceSyncOptions;

@protocol MenuItemSourcePostAbstractViewSubclass <NSObject>
- (Class)entityClass;
- (MenuPostServiceSyncOptions *)syncOptions;
@end

NS_ASSUME_NONNULL_END
