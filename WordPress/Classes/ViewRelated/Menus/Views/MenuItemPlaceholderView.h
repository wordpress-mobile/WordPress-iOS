#import "MenuItemsActionableView.h"

typedef NS_ENUM(NSUInteger) {
    MenuItemPlaceholderViewAbove = 1,
    MenuItemPlaceholderViewBelow,
    MenuItemPlaceholderViewChild
}MenuItemPlaceholderViewType;

@interface MenuItemPlaceholderView : MenuItemsActionableView

@property (nonatomic, assign) MenuItemPlaceholderViewType type;

@end
