#import <UIKit/UIKit.h>

@class Menu;

@protocol MenuDetailsViewControllerDelegate;

@interface MenuDetailsViewController : UIViewController

@property (nonatomic, weak) id <MenuDetailsViewControllerDelegate> delegate;
@property (nonatomic, strong) Menu *menu;

@end

@protocol MenuDetailsViewControllerDelegate <NSObject>

/**
 User updated the name of the Menu associated with the detailView.
 */
- (void)detailsViewControllerUpdatedMenuName:(MenuDetailsViewController *)detailsViewController;

/**
 User selected to delete the Menu associated with the detailView.
 */
- (void)detailsViewControllerSelectedToDeleteMenu:(MenuDetailsViewController *)detailsViewController;

@end
