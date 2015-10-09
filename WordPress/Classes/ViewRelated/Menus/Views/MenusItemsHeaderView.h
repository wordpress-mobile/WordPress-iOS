#import <UIKit/UIKit.h>

@class Menu;

@interface MenusItemsHeaderView : UIView

@property (nonatomic, strong) Menu *menu;

+ (MenusItemsHeaderView *)headerViewFromNib;

@end
