#import <UIKit/UIKit.h>
#import "MenuItem.h"

NS_ASSUME_NONNULL_BEGIN

@class Blog;

@protocol MenuItemTypeViewControllerDelegate;

@interface MenuItemTypeViewController : UIViewController

@property (nonatomic, weak, nullable) id <MenuItemTypeViewControllerDelegate> delegate;

/**
 The itemType to display as selected in the UI, such as MenuItemTypePage.
 */
@property (nonatomic, strong) NSString *selectedItemType;

/**
 Fetch the postTypes available for the blog, including custom post types.
 */
- (void)loadPostTypesForBlog:(Blog *)blog;

/**
 Helper method for updating the layout if the parentView's layout changed.
 */
- (void)updateDesignForLayoutChangeIfNeeded;

/**
 Ensure the selected itemType is viisble on screen.
 */
- (void)focusSelectedTypeViewIfNeeded:(BOOL)animated;

@end

@protocol MenuItemTypeViewControllerDelegate <NSObject>

/**
 User selected an itemType.
 */
- (void)itemTypeViewController:(MenuItemTypeViewController *)itemTypeViewController selectedType:(NSString *)itemType;

/**
 Helper method for the parentView informing the ideal layout for the view.
 */
- (BOOL)itemTypeViewControllerShouldDisplayFullSizedLayout:(MenuItemTypeViewController *)itemTypeViewController;

@end

NS_ASSUME_NONNULL_END
