#import <UIKit/UIKit.h>

@protocol MenuItemSourceSearchBarDelegate;

@interface MenuItemSourceSearchBar : UIView

@property (nonatomic, weak) id <MenuItemSourceSearchBarDelegate> delegate;

@end

@protocol MenuItemSourceSearchBarDelegate <NSObject>

- (void)sourceSearchBarDidBeginSearching:(MenuItemSourceSearchBar *)searchBar;
- (void)sourceSearchBar:(MenuItemSourceSearchBar *)searchBar didUpdateSearchWithText:(NSString *)text;
- (void)sourceSearchBarDidEndSearching:(MenuItemSourceSearchBar *)searchBar;

@end