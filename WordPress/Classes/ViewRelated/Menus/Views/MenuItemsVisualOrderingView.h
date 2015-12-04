#import <UIKit/UIKit.h>

@class MenuItem;
@class MenuItemView;

@interface MenuItemsVisualOrderingView : UIView

- (void)setVisualOrderingForItemView:(MenuItemView *)orderingView;
- (void)updateForOrderingMenuItemsModelChange;
- (void)updateWithTouchLocation:(CGPoint)touchLocation vector:(CGPoint)vector;

@end
