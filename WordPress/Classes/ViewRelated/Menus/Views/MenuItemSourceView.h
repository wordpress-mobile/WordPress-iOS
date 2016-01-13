#import <UIKit/UIKit.h>
#import "MenuItemSourceSearchBar.h"

@class MenuItem;

@protocol MenuItemSourceViewDelegate;

@interface MenuItemSourceView : UIView <MenuItemSourceSearchBarDelegate>

@property (nonatomic, weak) id <MenuItemSourceViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) MenuItemSourceSearchBar *searchBar;

- (void)insertSearchBarIfNeeded;

@end

@protocol MenuItemSourceViewDelegate <NSObject>

- (void)sourceViewDidBeginEditingWithKeyBoard:(MenuItemSourceView *)sourceView;
- (void)sourceViewDidEndEditingWithKeyboard:(MenuItemSourceView *)sourceView;

@end