#import <UIKit/UIKit.h>

@protocol MenuItemTypeHeaderViewDelegate;

@interface MenuItemTypeHeaderView : UIView

@property (nonatomic, weak) id <MenuItemTypeHeaderViewDelegate> delegate;

@end

@protocol MenuItemTypeHeaderViewDelegate <NSObject>

- (void)itemTypeViewSelected:(MenuItemTypeHeaderView *)typeView;

@end