#import "MenuItemAbstractView.h"

typedef NS_ENUM(NSUInteger, MenuItemInsertionOrder) {
    MenuItemInsertionOrderAbove = 1,
    MenuItemInsertionOrderBelow,
    MenuItemInsertionOrderChild
};

@protocol MenuItemInsertionViewDelegate;

/**
 An a view encapsulating work for inserting new MenuItems in MenuItemsViewController.
 */
@interface MenuItemInsertionView : MenuItemAbstractView

@property (nonatomic, weak) id <MenuItemAbstractViewDelegate, MenuItemInsertionViewDelegate> delegate;

/**
 The type of insertion the view represents.
 */
@property (nonatomic, assign) MenuItemInsertionOrder insertionOrder;

@end

@protocol MenuItemInsertionViewDelegate <MenuItemAbstractViewDelegate>

/**
 User interaction detected for selecting the insertion.
 */
- (void)itemInsertionViewSelected:(MenuItemInsertionView *)insertionView;

@end
