#import <UIKit/UIKit.h>

@class MenuItem;

@protocol MenuItemEditingHeaderViewDelegate;

@interface MenuItemEditingHeaderView : UIView

@property (nonatomic, weak) id <MenuItemEditingHeaderViewDelegate> delegate;
@property (nonatomic, strong) NSString *itemType;
@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, strong) UITextField *textField;

- (void)setNeedsTopConstraintsUpdateForStatusBarAppearence:(BOOL)hidden;

@end

@protocol MenuItemEditingHeaderViewDelegate <NSObject>

- (void)editingHeaderViewDidUpdateItem:(MenuItemEditingHeaderView *)headerView;

@end
