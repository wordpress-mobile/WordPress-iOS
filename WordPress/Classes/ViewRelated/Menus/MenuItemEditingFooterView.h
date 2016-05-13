#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MenuItem;

@protocol MenuItemEditingFooterViewDelegate;

@interface MenuItemEditingFooterView : UIView

@property (nonatomic, weak, nullable) id <MenuItemEditingFooterViewDelegate> delegate;

@end

@protocol MenuItemEditingFooterViewDelegate <NSObject>

- (void)editingFooterViewDidSelectSave:(MenuItemEditingFooterView *)footerView;
- (void)editingFooterViewDidSelectTrash:(MenuItemEditingFooterView *)footerView;
- (void)editingFooterViewDidSelectCancel:(MenuItemEditingFooterView *)footerView;

@end

NS_ASSUME_NONNULL_END
