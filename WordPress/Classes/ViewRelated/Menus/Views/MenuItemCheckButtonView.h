#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MenuItemCheckButtonView : UIView

/**
 Label used alongside the checkbox.
 */
@property (nonatomic, strong, readonly) UILabel *label;

/**
 Checked state of the view.
 */
@property (nonatomic, assign) BOOL checked;

/**
 Event handler if the checked state changes.
 */
@property (nonatomic, copy, nullable) void(^onChecked)(void);

/**
 Ideal layout height of the view.
 */
- (CGFloat)preferredHeightForLayout;

@end

NS_ASSUME_NONNULL_END
