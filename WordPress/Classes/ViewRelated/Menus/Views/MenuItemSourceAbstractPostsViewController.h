#import "MenuItemSourceResultsViewController.h"

@interface MenuItemSourceAbstractPostsViewController : MenuItemSourceResultsViewController

@end

@class PostServiceSyncOptions;

@protocol MenuItemSourcePostAbstractViewSubclass <NSObject>
- (Class)entityClass;
- (PostServiceSyncOptions *)syncOptions;
@end
