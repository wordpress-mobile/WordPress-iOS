#import <UIKit/UIKit.h>

@class MenuItem;

@protocol MenuItemEditingFooterViewDelegate;

@interface MenuItemEditingFooterView : UIView

@property (nonatomic, weak) id <MenuItemEditingFooterViewDelegate> delegate;
@property (nonatomic, strong) MenuItem *item;

@end

@protocol MenuItemEditingFooterViewDelegate <NSObject>

- (void)editingFooterViewDidSelectCancel:(MenuItemEditingFooterView *)footerView;

@end