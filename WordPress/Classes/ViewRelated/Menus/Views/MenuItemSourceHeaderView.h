#import <UIKit/UIKit.h>
#import "MenuItem.h"

@protocol MenuItemSourceHeaderViewDelegate;

@interface MenuItemSourceHeaderView : UIView

@property (nonatomic, weak) id <MenuItemSourceHeaderViewDelegate> delegate;

/**
 Title label used for displaying header text for a MenuItem.
 */
@property (nonatomic, strong, readonly) UILabel *titleLabel;

@end

@protocol MenuItemSourceHeaderViewDelegate <NSObject>

/**
 User interaction detected a tap for toggling/selecting the headerView.
 */
- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView;

@end