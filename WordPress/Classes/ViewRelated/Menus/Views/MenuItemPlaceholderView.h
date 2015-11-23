#import "MenuItemsStackableView.h"

typedef NS_ENUM(NSUInteger) {
    MenuItemPlaceholderViewTypeAbove = 1,
    MenuItemPlaceholderViewTypeBelow,
    MenuItemPlaceholderViewTypeChild
}MenuItemPlaceholderViewType;

@protocol MenuItemPlaceholderViewDelegate;

@interface MenuItemPlaceholderView : MenuItemsStackableView

@property (nonatomic, weak) id <MenuItemsStackableViewDelegate, MenuItemPlaceholderViewDelegate> delegate;
@property (nonatomic, assign) MenuItemPlaceholderViewType type;

@end

@protocol MenuItemPlaceholderViewDelegate <MenuItemsStackableViewDelegate>

- (void)itemPlaceholderViewSelected:(MenuItemPlaceholderView *)placeholderView;

@end
