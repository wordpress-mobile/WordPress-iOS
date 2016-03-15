#import "MenuItemSourceView.h"

@interface MenuItemSourcePostAbstractView : MenuItemSourceView

@end

@class PostServiceSyncOptions;

@protocol MenuItemSourcePostAbstractViewSubclass <NSObject>
- (Class)entityClass;
- (PostServiceSyncOptions *)syncOptions;
@end
