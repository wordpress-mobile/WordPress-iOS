#import <UIKit/UIKit.h>

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
@property (nonatomic, copy) void(^onChecked)();

/**
 Ideal layout height of the view.
 */
- (CGFloat)preferredHeightForLayout;

@end
