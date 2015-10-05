#import "MenusSelectionCell.h"

@class MenuLocation;

@interface MenusLocationCell : MenusSelectionCell

@property (nonatomic, strong) MenuLocation *location;

+ (CGFloat)heightForTableView:(UITableView *)tableView location:(MenuLocation *)location;

@end
