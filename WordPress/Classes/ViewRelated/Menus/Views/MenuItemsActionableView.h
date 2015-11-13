#import <UIKit/UIKit.h>

@interface MenuItemsActionableView : UIView

@property (nonatomic, weak) MenuItemsActionableView *previousView;
@property (nonatomic, weak) MenuItemsActionableView *nextView;
@property (nonatomic, assign) NSUInteger indentationLevel;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *iconView;

- (UIColor *)highlightedColor;

@end
