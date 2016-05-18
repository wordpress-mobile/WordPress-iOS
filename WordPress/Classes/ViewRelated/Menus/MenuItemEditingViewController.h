#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MenuItem;
@class Blog;

extern NSString * const MenuItemEditingTypeSelectionChangedNotification;

@interface MenuItemEditingViewController : UIViewController

/**
 Completion handler to call when the user has selected to save changes.
 */
@property (nonatomic, copy, nullable) void(^onSelectedToSave)();

/**
 Completion handler to call when the user has selected to delete the item.
 */
@property (nonatomic, copy, nullable) void(^onSelectedToTrash)();

/**
 Completion handler to call when the user has selected to cancel changes to the item.
 */
@property (nonatomic, copy, nullable) void(^onSelectedToCancel)();

- (id)initWithItem:(MenuItem *)item blog:(Blog *)blog;

@end

NS_ASSUME_NONNULL_END
