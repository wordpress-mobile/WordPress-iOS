#import "MenuItemsStackableView.h"

typedef NS_ENUM(NSUInteger) {
    MenuItemInsertionViewTypeAbove = 1,
    MenuItemInsertionViewTypeBelow,
    MenuItemInsertionViewTypeChild
}MenuItemInsertionViewType;

@protocol MenuItemInsertionViewDelegate;

@interface MenuItemInsertionView : MenuItemsStackableView

@property (nonatomic, weak) id <MenuItemsStackableViewDelegate, MenuItemInsertionViewDelegate> delegate;
@property (nonatomic, assign) MenuItemInsertionViewType type;

@end

@protocol MenuItemInsertionViewDelegate <MenuItemsStackableViewDelegate>

- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView;

@end
