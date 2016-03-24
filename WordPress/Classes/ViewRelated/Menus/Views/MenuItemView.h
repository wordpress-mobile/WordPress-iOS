#import "MenuItemsStackableView.h"

@class MenuItem;

@protocol MenuItemViewDelegate;

@interface MenuItemView : MenuItemsStackableView

@property (nonatomic, weak) id <MenuItemsStackableViewDelegate, MenuItemViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, assign) BOOL showsEditingButtonOptions;
@property (nonatomic, assign) BOOL showsCancelButtonOption;

- (void)refresh;

@end

@protocol MenuItemViewDelegate <NSObject>

- (void)itemViewSelected:(MenuItemView *)itemView;
- (void)itemViewEditingButtonPressed:(MenuItemView *)itemView;
- (void)itemViewAddButtonPressed:(MenuItemView *)itemView;
- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView;

@end