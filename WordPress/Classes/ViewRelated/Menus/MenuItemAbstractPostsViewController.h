#import "MenuItemSourceResultsViewController.h"

@interface MenuItemAbstractPostsViewController : MenuItemSourceResultsViewController

@end

@class PostServiceSyncOptions;

@protocol MenuItemSourcePostAbstractViewSubclass <NSObject>
- (Class)entityClass;
- (PostServiceSyncOptions *)syncOptions;
@end
