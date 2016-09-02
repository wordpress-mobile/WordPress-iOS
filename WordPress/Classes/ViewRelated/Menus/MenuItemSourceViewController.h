#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class MenuItem;

@protocol MenuItemSourceViewControllerDelegate;

@interface MenuItemSourceViewController : UIViewController

@property (nonatomic, weak, nullable) id <MenuItemSourceViewControllerDelegate> delegate;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenuItem *item;

/**
 Toggle whether or not the item type header view is hidden.
 */
- (void)setHeaderViewHidden:(BOOL)hidden;

/**
 Toggle which sourceView should display based on the itemType.
 */
- (void)updateSourceSelectionForItemType:(NSString *)itemType;

/**
 Inform the view to refresh if the item's name was edited outside of this view.
 */
- (void)refreshForUpdatedItemName;

@end

@protocol MenuItemSourceViewControllerDelegate <NSObject>

/**
 Changes were made to the associated MenuItem.
 */
- (void)sourceResultsViewControllerDidUpdateItem:(MenuItemSourceViewController *)sourceViewController;

/**
 User pressed the headerView to change the toggle itemType.
 */
- (void)sourceViewControllerTypeHeaderViewWasPressed:(MenuItemSourceViewController *)sourceViewController;

/**
 Helper method for updating any layout constraints for keyboard changes.
 */
- (void)sourceViewControllerDidBeginEditingWithKeyboard:(MenuItemSourceViewController *)sourceViewController;

/**
 Helper method for updating any layout constraints for keyboard changes.
 */
- (void)sourceViewControllerDidEndEditingWithKeyboard:(MenuItemSourceViewController *)sourceViewController;

@end

NS_ASSUME_NONNULL_END
