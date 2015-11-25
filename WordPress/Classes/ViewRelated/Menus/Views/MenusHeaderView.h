#import <UIKit/UIKit.h>

@class Blog;
@class MenuLocation;
@class Menu;

@protocol MenusHeaderViewDelegate;

@interface MenusHeaderView : UIView

@property (nonatomic, weak) id <MenusHeaderViewDelegate> delegate;

- (void)updateWithMenusForBlog:(Blog *)blog;
- (void)refreshMenuViewsUsingMenu:(Menu *)menu;

@end

@protocol MenusHeaderViewDelegate <NSObject>

- (void)headerViewSelectionChangedWithSelectedLocation:(MenuLocation *)location;
- (void)headerViewSelectionChangedWithSelectedMenu:(Menu *)menu;

@end
