#import <UIKit/UIKit.h>

@class Blog;
@class MenuItem;

@protocol MenuItemSourceContainerViewDelegate;

@interface MenuItemSourceContainerView : UIView

@property (nonatomic, weak) id <MenuItemSourceContainerViewDelegate> delegate;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenuItem *item;

/**
 Toggled which sourceView should display based on the itemType.
 */
- (void)updateSourceSelectionForItemType:(NSString *)itemType;

/**
 Inform the view to refresh if the item's name was edited outside of this view.
 */
- (void)refreshForUpdatedItemName;

@end

@protocol MenuItemSourceContainerViewDelegate <NSObject>

/**
 Changes were made to the associated MenuItem.
 */
- (void)sourceContainerViewDidUpdateItem:(MenuItemSourceContainerView *)sourceContainerView;

/**
 User selected the headerView to change the selected itemType.
 */
- (void)sourceContainerViewSelectedTypeHeaderView:(MenuItemSourceContainerView *)sourceContainerView;

/**
 Helper method for updating any layout constraints for keyboard changes.
 */
- (void)sourceContainerViewDidBeginEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;

/**
 Helper method for updating any layout constraints for keyboard changes.
 */
- (void)sourceContainerViewDidEndEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;

@end