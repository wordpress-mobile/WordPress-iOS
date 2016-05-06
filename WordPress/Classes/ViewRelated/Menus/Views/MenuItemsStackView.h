#import <UIKit/UIKit.h>

@class Menu;
@class MenuItem;

@protocol MenuItemsStackViewDelegate;

@interface MenuItemsStackView : UIViewController

@property (nonatomic, weak) id <MenuItemsStackViewDelegate> delegate;
@property (nonatomic, strong) Menu *menu;

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

@protocol MenuItemsStackViewDelegate <NSObject>

/**
 User created a new (empty) MenuItem.
 */
- (void)itemsView:(MenuItemsStackView *)itemsView createdNewItemForEditing:(MenuItem *)item;

/**
 User selected an item for editing it.
 */
- (void)itemsView:(MenuItemsStackView *)itemsView selectedItemForEditing:(MenuItem *)item;

/**
 User updated the ordering of the Menu's items.
 */
- (void)itemsView:(MenuItemsStackView *)itemsView didUpdateMenuItemsOrdering:(Menu *)menu;

/**
 User interaction triggered a need for scrolling a view to the center of any parent scrollViews.
 */
- (void)itemsView:(MenuItemsStackView *)itemsView requiresScrollingToCenterView:(UIView *)viewForScrolling;

/**
 User interaction triggered that may require enabling/disabling scrolling for any parent scrollViews.
 */
- (void)itemsView:(MenuItemsStackView *)itemsView prefersScrollingEnabled:(BOOL)enabled;

/**
 User interaction triggered that may require an offset update for a rect change of the view within any parent scrollViews.
 */
- (void)itemsView:(MenuItemsStackView *)itemsView prefersAdjustingScrollingOffsetForAnimatingView:(UIView *)view;

/**
 User interaction triggered a change in a specific view's rect that may require an offset change for any parent scrollViews.
 */
- (void)itemsViewAnimatingContentSizeChanges:(MenuItemsStackView *)itemsView focusedRect:(CGRect)focusedRect updatedFocusRect:(CGRect)updatedFocusRect;

@end