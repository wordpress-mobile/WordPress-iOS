#import <UIKit/UIKit.h>

@class MenuItem;

@protocol MenuItemEditingHeaderViewDelegate;

@interface MenuItemEditingHeaderView : UIView

@property (nonatomic, weak) id <MenuItemEditingHeaderViewDelegate> delegate;

@property (nonatomic, strong) MenuItem *item;

/**
 The itemType the header should display such as MenuItemTypePage.
 */
@property (nonatomic, strong) NSString *itemType;

/**
 Texfield for editing the name of the item.
 */
@property (nonatomic, strong) UITextField *textField;

/**
 Helper method for updating the layout based on statusBar changes.
 */
- (void)setNeedsTopConstraintsUpdateForStatusBarAppearence:(BOOL)hidden;

@end

@protocol MenuItemEditingHeaderViewDelegate <NSObject>

/**
 The user updated the item, such as the name of the item.
 */
- (void)editingHeaderViewDidUpdateItem:(MenuItemEditingHeaderView *)headerView;

@end
