#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MenuItem;

@protocol MenuItemEditingHeaderViewDelegate;

@interface MenuItemEditingHeaderView : UIView

@property (nonatomic, weak, nullable) id <MenuItemEditingHeaderViewDelegate> delegate;

@property (nonatomic, strong) MenuItem *item;

/**
 The itemType the header should display such as MenuItemTypePage.
 */
@property (nonatomic, strong) NSString *itemType;

/**
 Texfield for editing the name of the item.
 */
@property (nonatomic, strong, readonly) UITextField *textField;

/**
 Helper method for updating the layout based on statusBar changes.
 */
- (void)setNeedsTopConstraintsUpdateForStatusBarAppearence:(BOOL)hidden;

@end

@protocol MenuItemEditingHeaderViewDelegate <NSObject>

/**
 The user updated the item name text.
 */
- (void)editingHeaderView:(MenuItemEditingHeaderView *)headerView didUpdateTextForItemName:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
