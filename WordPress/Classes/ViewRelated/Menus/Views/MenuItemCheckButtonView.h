#import <UIKit/UIKit.h>

@interface MenuItemCheckButtonView : UIView

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, assign) BOOL checked;
@property (nonatomic, copy) void(^onChecked)();

- (CGFloat)preferredHeightForLayout;

@end
