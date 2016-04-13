#import <UIKit/UIKit.h>

extern CGFloat const MenuItemsStackableViewDefaultHeight;

@protocol MenuItemDrawingViewDelegate <NSObject>
- (void)drawingViewDrawRect:(CGRect)rect;
@end

@interface MenuItemDrawingView : UIView

@end

@protocol MenuItemsStackableViewDelegate;

@interface MenuItemsStackableView : UIView <MenuItemDrawingViewDelegate>

@property (nonatomic, weak) id <MenuItemsStackableViewDelegate> delegate;
@property (nonatomic, strong) MenuItemDrawingView *contentView;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) BOOL isPlaceholder;
@property (nonatomic, assign) BOOL drawsLineSeparator;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *iconView;

@property (nonatomic, weak) MenuItemsStackableView *previous;
@property (nonatomic, weak) MenuItemsStackableView *next;

- (void)addAccessoryButton:(UIButton *)button;
- (UIButton *)addAccessoryButtonIconViewWithImage:(UIImage *)image;

// called on init and when highlighted value changes
- (UIColor *)contentViewBackgroundColor;
- (UIColor *)textLabelColor;
- (UIColor *)iconTintColor;

@end

@protocol MenuItemsStackableViewDelegate <NSObject>
@optional

@end
