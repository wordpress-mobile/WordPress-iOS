#import <UIKit/UIKit.h>
#import "MenuItemSourceResultView.h"
#import "MenuItem.h"

@protocol MenuItemSourceContainerViewDelegate;

@interface MenuItemSourceContainerView : UIView

@property (nonatomic, weak) id <MenuItemSourceContainerViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, assign) MenuItemType selectedItemType;

@end

@protocol MenuItemSourceContainerViewDelegate <NSObject>

- (void)sourceContainerViewSelectedTypeHeaderView:(MenuItemSourceContainerView *)sourceContainerView;
- (void)sourceContainerViewDidBeginEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;
- (void)sourceContainerViewDidEndEditingWithKeyboard:(MenuItemSourceContainerView *)sourceContainerView;

@end