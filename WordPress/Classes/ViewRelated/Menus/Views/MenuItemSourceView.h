#import <UIKit/UIKit.h>
#import "MenuItemSourceTextBar.h"
#import "MenuItemSourceCell.h"

@class MenuItem;

@protocol MenuItemSourceViewDelegate;

@interface MenuItemSourceView : UIView <MenuItemSourceTextBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <MenuItemSourceViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;

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

/* Methods for subclasses to handle the configuraton and data sources of the tableView within the sourceView
 */
- (NSInteger)numberOfSourceTableSections;
- (NSInteger)numberOfSourcesInTableSection:(NSInteger)section;
- (void)willDisplaySourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath;

@end

@protocol MenuItemSourceViewDelegate <NSObject>

- (void)sourceViewDidBeginEditingWithKeyBoard:(MenuItemSourceView *)sourceView;
- (void)sourceViewDidEndEditingWithKeyboard:(MenuItemSourceView *)sourceView;

@end