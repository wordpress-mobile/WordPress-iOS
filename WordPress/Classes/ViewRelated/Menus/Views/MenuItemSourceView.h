#import <UIKit/UIKit.h>
#import "MenuItemSourceHeaderView.h"
#import "MenuItemSourceResultView.h"
#import "MenuItemSourceSearchBar.h"
#import "MenuItem.h"

@protocol MenuItemSourceViewDelegate;

@interface MenuItemSourceView : UIView <MenuItemSourceSearchBarDelegate>

@property (nonatomic, weak) id <MenuItemSourceViewDelegate> delegate;
@property (nonatomic, strong) MenuItemSourceHeaderView *headerView;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, assign) MenuItemType selectedItemType;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong, readonly) MenuItemSourceSearchBar *searchBar;

- (void)reloadResults;
- (void)activateHeightConstraintForHeaderViewWithHeightAnchor:(NSLayoutAnchor *)heightAnchor;

@end

@protocol MenuItemSourceViewDelegate <NSObject>

- (void)sourceViewSelectedSourceTypeButton:(MenuItemSourceView *)sourceView;
- (void)sourceViewDidBeginTyping:(MenuItemSourceView *)sourceView;
- (void)sourceViewDidEndTyping:(MenuItemSourceView *)sourceView;

@end