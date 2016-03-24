#import <UIKit/UIKit.h>

@class MenuItem;
@class Blog;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MenuItemEditingTypeSelectionChangedNotification;

@interface MenuItemEditingViewController : UIViewController

@property (nonatomic, copy) void(^onSelectedToSave)();
@property (nonatomic, copy) void(^onSelectedToTrash)();
@property (nonatomic, copy) void(^onSelectedToCancel)();

- (id)initWithItem:(MenuItem *)item blog:(Blog *)blog;

@end

NS_ASSUME_NONNULL_END
