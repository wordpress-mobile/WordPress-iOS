#import <UIKit/UIKit.h>

@class Menu;

@protocol MenuItemsStackViewDelegate;

@interface MenuItemsStackView : UIView

@property (nonatomic, weak) id <MenuItemsStackViewDelegate> delegate;
@property (nonatomic, strong) Menu *menu;

@end

@protocol MenuItemsStackViewDelegate <NSObject>

- (void)itemsView:(MenuItemsStackView *)itemsView prefersScrollingEnabled:(BOOL)enabled;
- (void)itemsViewAnimatingContentSizeChanges:(MenuItemsStackView *)itemsView focusedRect:(CGRect)focusedRect updatedFocusRect:(CGRect)updatedFocusRect;

@end
