#import "MenuItemActionableView.h"

@class MenuItem;

@protocol MenuItemViewDelegate;

@interface MenuItemView : MenuItemActionableView

@property (nonatomic, weak) id <MenuItemActionableViewDelegate, MenuItemViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, assign) BOOL showsEditingButtonOptions;
@property (nonatomic, assign) BOOL showsCancelButtonOption;

@end

@protocol MenuItemViewDelegate <NSObject>

- (void)itemViewAddButtonPressed:(MenuItemView *)itemView;
- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView;

@end