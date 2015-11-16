#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger) {
    MenuItemsActionableIconNone,
    MenuItemsActionableIconDefault,
    MenuItemsActionableIconEdit,
    MenuItemsActionableIconAdd,
}MenuItemsActionableIconType;

extern CGFloat const MenuItemsActionableViewDefaultHeight;
extern CGFloat const MenuItemsActionableViewAccessoryButtonHeight;

@interface MenuItemDrawingView : UIView

@end

@interface MenuItemsActionableView : UIView

@property (nonatomic, strong) MenuItemDrawingView *contentView;
@property (nonatomic, weak) MenuItemsActionableView *previousView;
@property (nonatomic, weak) MenuItemsActionableView *nextView;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) NSUInteger indentationLevel;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) MenuItemsActionableIconType iconType;

- (void)addAccessoryButton:(UIButton *)button;
- (UIButton *)addAccessoryButtonIconViewWithType:(MenuItemsActionableIconType)type;

// called on init and when highlighted value changes
- (UIColor *)contentViewBackgroundColor;
- (UIColor *)textLabelColor;
- (UIColor *)iconTintColor;

@end
