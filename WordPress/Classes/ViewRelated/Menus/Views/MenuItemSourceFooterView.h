#import <UIKit/UIKit.h>

@interface MenuItemSourceFooterView : UIView

@property (nonatomic, assign) BOOL isAnimating;

- (void)startLoadingIndicatorAnimation;
- (void)stopLoadingIndicatorAnimation;

@end
