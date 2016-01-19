#import <UIKit/UIKit.h>
#import "MenuItemSourceTextBar.h"
#import "MenuItemSourceCell.h"

@class MenuItem;

@protocol MenuItemSourceViewDelegate;

@interface MenuItemSourceView : UIView <MenuItemSourceTextBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <MenuItemSourceViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;

/* Sources resulting from a sourceView's data
 */
@property (nonatomic, strong) NSMutableArray <MenuItemSource *> *sources;

/* A stackView for adding any views that aren't cells before the tableView, Ex. searchBar, label, design views
 */
@property (nonatomic, strong, readonly) UIStackView *stackView;

/* A tableView for inserting cells of data relating to the source
 */
@property (nonatomic, strong, readonly) UITableView *tableView;

/* Searchbar created and implemented via insertSearchBarIfNeeded
 */
@property (nonatomic, strong) MenuItemSourceTextBar *searchBar;

- (void)insertSearchBarIfNeeded;

@end

@protocol MenuItemSourceViewDelegate <NSObject>

- (void)sourceViewDidBeginEditingWithKeyBoard:(MenuItemSourceView *)sourceView;
- (void)sourceViewDidEndEditingWithKeyboard:(MenuItemSourceView *)sourceView;

@end