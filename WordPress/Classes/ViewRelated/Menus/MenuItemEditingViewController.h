#import <UIKit/UIKit.h>

@class MenuItem;
@class Blog;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MenuItemEditingTypeSelectionChangedNotification;

@interface MenuItemEditingViewController : UIViewController

- (id)initWithItem:(MenuItem *)item blog:(Blog *)blog;
- (MenuItem *)item;

@end

NS_ASSUME_NONNULL_END
