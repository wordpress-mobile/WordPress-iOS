#import "MenuItemAbstractView.h"

NS_ASSUME_NONNULL_BEGIN

@class MenuItem;

@protocol MenuItemViewDelegate;

/**
 View that encapsulates the display and editing actions for a MenuItem within MenuItemsViewController.
 */
@interface MenuItemView : MenuItemAbstractView

@property (nonatomic, weak, nullable) id <MenuItemAbstractViewDelegate, MenuItemViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;

/**
 Show the add and ordering buttons for the item.
 */
@property (nonatomic, assign) BOOL showsEditingButtonOptions;

/**
 Show the cancel button for canceling adding new items around the view.
 */
@property (nonatomic, assign) BOOL showsCancelButtonOption;

/**
 Refresh the content based on the item.
 */
- (void)refresh;

/**
 The detectedable region of the view for allowing ordering.
 */
- (CGRect)orderingToggleRect;

@end

@protocol MenuItemViewDelegate <NSObject>

/**
 User interaction detected for selecting the item.
 */
- (void)itemViewSelected:(MenuItemView *)itemView;

/**
 User interaction detected for adding a new item around this view.
 */
- (void)itemViewAddButtonPressed:(MenuItemView *)itemView;

/**
 User interaction detected for canceling adding a new item around this view.
 */
- (void)itemViewCancelButtonPressed:(MenuItemView *)itemView;

@end

NS_ASSUME_NONNULL_END
