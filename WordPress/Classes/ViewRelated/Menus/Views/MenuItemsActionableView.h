#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger) {
    MenuItemsActionableIconNone,
    MenuItemsActionableIconDefault,
    MenuItemsActionableIconEdit,
    MenuItemsActionableIconAdd,
}MenuItemsActionableIconType;

@interface MenuItemsActionableView : UIView

@property (nonatomic, weak) MenuItemsActionableView *previousView;
@property (nonatomic, weak) MenuItemsActionableView *nextView;
@property (nonatomic, assign) NSUInteger indentationLevel;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) MenuItemsActionableIconType iconType;

- (UIColor *)highlightedColor;
- (UIButton *)newButtonIconViewWithType:(MenuItemsActionableIconType)type;

@end
