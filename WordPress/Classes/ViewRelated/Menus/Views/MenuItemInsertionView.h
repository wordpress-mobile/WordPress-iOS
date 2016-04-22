#import "MenuItemsStackableView.h"

typedef NS_ENUM(NSUInteger, MenuItemInsertionOrder) {
    MenuItemInsertionOrderAbove = 1,
    MenuItemInsertionOrderBelow,
    MenuItemInsertionOrderChild
};

@protocol MenuItemInsertionViewDelegate;

@interface MenuItemInsertionView : MenuItemsStackableView

@property (nonatomic, weak) id <MenuItemsStackableViewDelegate, MenuItemInsertionViewDelegate> delegate;

/**
 The type of insertion the view represents.
 */
@property (nonatomic, assign) MenuItemInsertionOrder insertionOrder;

@end

@protocol MenuItemInsertionViewDelegate <MenuItemsStackableViewDelegate>

/**
 User interaction detected for selecting the insertion.
 */
- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView;

@end
