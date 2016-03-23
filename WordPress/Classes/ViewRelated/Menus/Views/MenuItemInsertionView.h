#import "MenuItemsStackableView.h"

typedef NS_ENUM(NSUInteger, MenuItemInsertionOrder) {
    MenuItemInsertionOrderAbove = 1,
    MenuItemInsertionOrderBelow,
    MenuItemInsertionOrderChild
};

@protocol MenuItemInsertionViewDelegate;

@interface MenuItemInsertionView : MenuItemsStackableView

@property (nonatomic, weak) id <MenuItemsStackableViewDelegate, MenuItemInsertionViewDelegate> delegate;
@property (nonatomic, assign) MenuItemInsertionOrder insertionOrder;

@end

@protocol MenuItemInsertionViewDelegate <MenuItemsStackableViewDelegate>

- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView;

@end
