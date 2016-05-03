#import <UIKit/UIKit.h>

@class Blog;
@class MenuLocation;
@class Menu;

@protocol MenusHeaderViewDelegate;

/**
 A top-most view encapsulating the use of
 two MenusSelectionViews to represent selection options for Menus and MenuLocations.
 */
@interface MenusHeaderView : UIView

@property (nonatomic, weak) id <MenusHeaderViewDelegate> delegate;
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

@protocol MenusHeaderViewDelegate <NSObject>

/**
 User selected a MenuLocation.
 */
- (void)headerView:(MenusHeaderView *)headerView selectedLocation:(MenuLocation *)location;

/**
 User selected a menu.
 */
- (void)headerView:(MenusHeaderView *)headerView selectedMenu:(Menu *)menu;

/**
 User selected the create new menu option.
 */
- (void)headerViewSelectedForCreatingNewMenu:(MenusHeaderView *)headerView;

@end
