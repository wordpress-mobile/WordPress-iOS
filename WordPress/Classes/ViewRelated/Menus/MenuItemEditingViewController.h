#import <UIKit/UIKit.h>

@class MenuItem;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MenuItemEditingTypeSelectionChangedNotification;

@interface MenuItemEditingViewController : UIViewController

@property (nonatomic, strong) MenuItem *item;

- (id)initWithItem:(MenuItem *)item;

@end

NS_ASSUME_NONNULL_END
