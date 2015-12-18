#import <UIKit/UIKit.h>
#import "MenuItemSourceResultView.h"
#import "MenuItemSourceSearchBar.h"

@class MenuItem;

@protocol MenuItemSourceViewDelegate;

@interface MenuItemSourceView : UIView <MenuItemSourceSearchBarDelegate>

@property (nonatomic, weak) id <MenuItemSourceViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) MenuItemSourceSearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *results;

- (void)reloadResults;

@end

@protocol MenuItemSourceViewDelegate <NSObject>

- (void)sourceViewDidBeginTyping:(MenuItemSourceView *)sourceView;
- (void)sourceViewDidEndTyping:(MenuItemSourceView *)sourceView;

@end