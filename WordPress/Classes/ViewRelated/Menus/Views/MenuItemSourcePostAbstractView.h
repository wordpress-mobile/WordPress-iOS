#import "MenuItemSourceView.h"

@interface MenuItemSourcePostAbstractView : MenuItemSourceView

@end

@class PostServiceSyncOptions;

@protocol MenuItemSourcePostAbstractViewSubclass <NSObject>
- (Class)entityClass;
- (NSString *)postServiceType;
- (PostServiceSyncOptions *)syncOptions;
@end
