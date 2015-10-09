#import "MenusSelectionCell.h"

@class Menu;

@interface MenusSelectedMenuCell : MenusSelectionCell

@property (nonatomic, strong) Menu *menu;

+ (CGFloat)heightForTableView:(UITableView *)tableView menu:(Menu *)menu;

@end
