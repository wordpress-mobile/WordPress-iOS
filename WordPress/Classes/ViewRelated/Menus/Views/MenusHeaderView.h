#import <UIKit/UIKit.h>

@class Blog;
@class MenuLocation;
@class Menu;

@protocol MenusHeaderViewDelegate;

@interface MenusHeaderView : UIView

@property (nonatomic, weak) id <MenusHeaderViewDelegate> delegate;

- (void)setupWithMenusForBlog:(Blog *)blog;
- (void)updateSelectionWithLocation:(MenuLocation *)location;
- (void)updateSelectionWithMenu:(Menu *)menu;
- (void)removeMenu:(Menu *)menu;
- (void)refreshMenuViewsUsingMenu:(Menu *)menu;

@end

@protocol MenusHeaderViewDelegate <NSObject>

- (void)headerView:(MenusHeaderView *)headerView selectionChangedWithSelectedLocation:(MenuLocation *)location;
- (void)headerView:(MenusHeaderView *)headerView selectionChangedWithSelectedMenu:(Menu *)menu;

@end
