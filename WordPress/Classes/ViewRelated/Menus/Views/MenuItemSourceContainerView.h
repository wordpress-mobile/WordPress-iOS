#import <UIKit/UIKit.h>

@class MenuItem;

@protocol MenuItemSourceContainerViewDelegate;

@interface MenuItemSourceContainerView : UIView

@property (nonatomic, weak) id <MenuItemSourceContainerViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;

- (void)updateSourceSelectionForItem;

@end

@protocol MenuItemSourceContainerViewDelegate <NSObject>

- (void)sourceContainerViewSelectedTypeHeaderView:(MenuItemSourceContainerView *)sourceContainerView;
- (void)sourceContainerViewDidBeginEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;
- (void)sourceContainerViewDidEndEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;

@end