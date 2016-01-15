#import <UIKit/UIKit.h>

@interface MenuItemCheckButtonView : UIView

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, assign) BOOL checked;

- (CGFloat)preferredHeightForLayout;

@end
