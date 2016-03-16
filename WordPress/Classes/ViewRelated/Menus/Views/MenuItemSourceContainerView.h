#import <UIKit/UIKit.h>

@class Blog;
@class MenuItem;

@protocol MenuItemSourceContainerViewDelegate;

@interface MenuItemSourceContainerView : UIView

@property (nonatomic, weak) id <MenuItemSourceContainerViewDelegate> delegate;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MenuItem *item;

/**
 Toggled which sourceView should display based on the itemType.
 */
- (void)updateSourceSelectionForItemType:(NSString *)itemType;

@end

@protocol MenuItemSourceContainerViewDelegate <NSObject>

- (void)sourceContainerViewSelectedTypeHeaderView:(MenuItemSourceContainerView *)sourceContainerView;
- (void)sourceContainerViewDidBeginEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;
- (void)sourceContainerViewDidEndEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;

@end