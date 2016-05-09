#import <UIKit/UIKit.h>

@class Menu;

@protocol MenuDetailsViewDelegate;

@interface MenuDetailsView : UIView

@property (nonatomic, weak) id <MenuDetailsViewDelegate> delegate;
@property (nonatomic, strong) Menu *menu;

@end

@protocol MenuDetailsViewDelegate <NSObject>

/**
 User updated the name of the Menu associated with the detailView.
 */
- (void)detailsViewUpdatedMenuName:(MenuDetailsView *)menuDetailView;

/**
 User selected to delete the Menu associated with the detailView.
 */
- (void)detailsViewSelectedToDeleteMenu:(MenuDetailsView *)menuDetailView;

@end
