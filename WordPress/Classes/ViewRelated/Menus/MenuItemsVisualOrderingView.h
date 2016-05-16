#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MenuItem;
@class MenuItemView;

@protocol MenuItemsVisualOrderingViewDelegate;

/**
 A view that manages the visual effect of a MenuItemView dragging across the screen for ordering in MenuItemsViewController.
 */
@interface MenuItemsVisualOrderingView : UIView

@property (nonatomic, weak, nullable) id <MenuItemsVisualOrderingViewDelegate> delegate;

/**
 Set up the view to copy the view's representation in the UI for animating it's ordering.
 */
- (void)setupVisualOrderingWithItemView:(MenuItemView *)itemView;

/**
 Update the visual itemView with a model change for its MenuItem.
 */
- (void)updateForVisualOrderingMenuItemsModelChange;

/**
 Update the location of the visual itemView according to related touches in a parentView.
 */
- (void)updateVisualOrderingWithTouchLocation:(CGPoint)touchLocation vector:(CGPoint)vector;

@end

@protocol MenuItemsVisualOrderingViewDelegate <NSObject>
@optional

/**
 The visual orderingView is animating and may require parent view changes to keep the view on screen.
 */
- (void)visualOrderingView:(MenuItemsVisualOrderingView *)visualOrderingView animatingVisualItemViewForOrdering:(MenuItemView *)orderingView;

@end

NS_ASSUME_NONNULL_END
