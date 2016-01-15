#import <UIKit/UIKit.h>

@class MenuItem;
@class MenuItemView;

@protocol MenuItemsVisualOrderingViewDelegate;

@interface MenuItemsVisualOrderingView : UIView

@property (nonatomic, weak) id <MenuItemsVisualOrderingViewDelegate> delegate;

- (void)setupVisualOrderingWithItemView:(MenuItemView *)itemView;
- (void)updateForVisualOrderingMenuItemsModelChange;
- (void)updateVisualOrderingWithTouchLocation:(CGPoint)touchLocation vector:(CGPoint)vector;

@end

@protocol MenuItemsVisualOrderingViewDelegate <NSObject>
@optional
- (void)visualOrderingView:(MenuItemsVisualOrderingView *)visualOrderingView animatingVisualItemViewForOrdering:(MenuItemView *)orderingView;
@end