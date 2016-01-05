#import <UIKit/UIKit.h>

@protocol MenuItemSourceHeaderViewDelegate;

@interface MenuItemSourceHeaderView : UIView

@property (nonatomic, weak) id <MenuItemSourceHeaderViewDelegate> delegate;

@end

@protocol MenuItemSourceHeaderViewDelegate <NSObject>

- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView;

@end