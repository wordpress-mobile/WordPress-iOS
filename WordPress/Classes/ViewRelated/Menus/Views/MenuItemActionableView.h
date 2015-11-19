#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger) {
    MenuItemActionableIconNone,
    MenuItemActionableIconDefault,
    MenuItemActionableIconEdit,
    MenuItemActionableIconAdd,
}MenuItemActionableIconType;

extern CGFloat const MenuItemActionableViewDefaultHeight;
extern CGFloat const MenuItemActionableViewAccessoryButtonHeight;

@protocol MenuItemDrawingViewDelegate <NSObject>
- (void)drawingViewDrawRect:(CGRect)rect;
@end

@interface MenuItemDrawingView : UIView

@end

@protocol MenuItemActionableViewDelegate;

@interface MenuItemActionableView : UIView <MenuItemDrawingViewDelegate>

@property (nonatomic, weak) id <MenuItemActionableViewDelegate> delegate;
@property (nonatomic, strong) MenuItemDrawingView *contentView;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) BOOL reorderingEnabled;
@property (nonatomic, assign) MenuItemActionableIconType iconType;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *iconView;

- (void)addAccessoryButton:(UIButton *)button;
- (UIButton *)addAccessoryButtonIconViewWithType:(MenuItemActionableIconType)type;
- (void)resetOrderingTouchesMovedVector;

// called on init and when highlighted value changes
- (UIColor *)contentViewBackgroundColor;
- (UIColor *)textLabelColor;
- (UIColor *)iconTintColor;

@end

@protocol MenuItemActionableViewDelegate <NSObject>
@optional
- (void)itemActionableViewDidBeginReordering:(MenuItemActionableView *)actionableView;
- (void)itemActionableView:(MenuItemActionableView *)actionableView orderingTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event vector:(CGPoint)vector;
- (void)itemActionableViewDidEndReordering:(MenuItemActionableView *)actionableView;
@end
