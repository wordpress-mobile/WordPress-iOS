#import <UIKit/UIKit.h>
#import "MenuItemSourceResultCell.h"

@class MenuItem;
@class MenuItemSourceSearchBar;

@interface MenuItemSourceView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) MenuItemSourceSearchBar *searchBar;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *results;

@end