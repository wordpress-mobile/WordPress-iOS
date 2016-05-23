#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class MenuLocation;
@class Menu;

@protocol MenuHeaderViewControllerDelegate;

/**
 A view controller encapsulating the use of
 two MenusSelectionViews to represent selection options for Menus and MenuLocations.
 */
@interface MenuHeaderViewController : UIViewController

@property (nonatomic, weak, nullable) id <MenuHeaderViewControllerDelegate> delegate;
@property (nonatomic, strong) Blog *blog;

/**
 Add a Menu to the header's selection options.
 */
- (void)addMenu:(Menu *)menu;

/**
 Remove a menu from the header's selection options.
 */
- (void)removeMenu:(Menu *)menu;

/**
 Set the header's currently selected MenuLocation.
 */
- (void)setSelectedLocation:(MenuLocation *)location;

/**
 Set the header's currently selected Menu.
 */
- (void)setSelectedMenu:(Menu *)menu;

/**
 Reload any views using data for Menu.
 */
- (void)refreshMenuViewsUsingMenu:(Menu *)menu;

@end

@protocol MenuHeaderViewControllerDelegate <NSObject>

/**
 User selected a MenuLocation.
 */
- (void)headerViewController:(MenuHeaderViewController *)headerViewController selectedLocation:(MenuLocation *)location;

/**
 User selected a menu.
 */
- (void)headerViewController:(MenuHeaderViewController *)headerViewController selectedMenu:(Menu *)menu;

/**
 User selected the create new menu option.
 */
- (void)headerViewControllerSelectedForCreatingNewMenu:(MenuHeaderViewController *)headerView;

@end

NS_ASSUME_NONNULL_END
