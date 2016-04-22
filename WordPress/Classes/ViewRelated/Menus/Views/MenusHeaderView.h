#import <UIKit/UIKit.h>

@class Blog;
@class MenuLocation;
@class Menu;

@protocol MenusHeaderViewDelegate;

@interface MenusHeaderView : UIView

@property (nonatomic, weak) id <MenusHeaderViewDelegate> delegate;

- (void)setupWithMenusForBlog:(Blog *)blog;
- (void)addMenu:(Menu *)menu;
- (void)removeMenu:(Menu *)menu;

- (void)setSelectedLocation:(MenuLocation *)location;
- (void)setSelectedMenu:(Menu *)menu;

- (void)refreshMenuViewsUsingMenu:(Menu *)menu;

@end

@protocol MenusHeaderViewDelegate <NSObject>

- (void)headerView:(MenusHeaderView *)headerView selectedLocation:(MenuLocation *)location;
- (void)headerView:(MenusHeaderView *)headerView selectedMenu:(Menu *)menu;
- (void)headerViewSelectedForCreatingNewMenu:(MenusHeaderView *)headerView;

@end
