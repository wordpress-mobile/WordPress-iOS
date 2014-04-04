#import <UIKit/UIKit.h>

@interface WPFixedWidthScrollView : UIScrollView

- (instancetype)initWithRootView:(UIView *)view;

@property (nonatomic, strong) UIView *rootView;
@property (nonatomic) CGFloat contentWidth;

@end
