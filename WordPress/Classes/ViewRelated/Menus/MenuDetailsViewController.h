#import <UIKit/UIKit.h>
#import <WordPressShared/WPAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@class Menu;

@protocol MenuDetailsViewControllerDelegate;

@interface MenuDetailsViewController : UIViewController

@property (nonatomic, weak, nullable) id <MenuDetailsViewControllerDelegate> delegate;
@property (nonatomic, strong, nullable) Menu *menu;

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

NS_ASSUME_NONNULL_END
