#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Menu;
@class MenuItem;

@protocol MenuItemsViewControllerDelegate;

@interface MenuItemsViewController : UIViewController

@property (nonatomic, weak, nullable) id <MenuItemsViewControllerDelegate> delegate;
@property (nonatomic, strong, nullable) Menu *menu;

/**
 Reload the views associated with the Menu's items.
 */
- (void)reloadItems;

/**
 Refresh the views associated with the specific item.
 */
- (void)refreshViewWithItem:(MenuItem *)item focus:(BOOL)focusesView;

/**
 Delete the MenuItem object and remove the view representing the item.
 */
- (void)removeItem:(MenuItem *)item;

@end

@protocol MenuItemsViewControllerDelegate <NSObject>

/**
 User created a new (empty) MenuItem.
 */
- (void)itemsViewController:(MenuItemsViewController *)itemsViewController createdNewItemForEditing:(MenuItem *)item;

/**
 User selected an item for editing it.
 */
- (void)itemsViewController:(MenuItemsViewController *)itemsViewController selectedItemForEditing:(MenuItem *)item;

/**
 User updated the ordering of the Menu's items.
 */
- (void)itemsViewController:(MenuItemsViewController *)itemsViewController didUpdateMenuItemsOrdering:(Menu *)menu;

/**
 User interaction triggered a need for scrolling a view to the center of any parent scrollViews.
 */
- (void)itemsViewController:(MenuItemsViewController *)itemsViewController requiresScrollingToCenterView:(UIView *)viewForScrolling;

/**
 User interaction triggered that may require enabling/disabling scrolling for any parent scrollViews.
 */
- (void)itemsViewController:(MenuItemsViewController *)itemsViewController prefersScrollingEnabled:(BOOL)enabled;

/**
 User interaction triggered that may require an offset update for a rect change of the view within any parent scrollViews.
 */
- (void)itemsViewController:(MenuItemsViewController *)itemsViewController prefersAdjustingScrollingOffsetForAnimatingView:(UIView *)view;

/**
 User interaction triggered a change in a specific view's rect that may require an offset change for any parent scrollViews.
 */
- (void)itemsViewAnimatingContentSizeChanges:(MenuItemsViewController *)itemsView focusedRect:(CGRect)focusedRect updatedFocusRect:(CGRect)updatedFocusRect;

@end

NS_ASSUME_NONNULL_END
