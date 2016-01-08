#import <UIKit/UIKit.h>
#import "MenuItem.h"

@protocol MenuItemSourceHeaderViewDelegate;

@interface MenuItemSourceHeaderView : UIView

@property (nonatomic, weak) id <MenuItemSourceHeaderViewDelegate> delegate;
@property (nonatomic, assign) MenuItemType itemType;

@end

@protocol MenuItemSourceHeaderViewDelegate <NSObject>

- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView;

@end