#import <UIKit/UIKit.h>

@interface MenuItemSourceFooterView : UIView

@property (nonatomic, assign) BOOL isAnimating;

- (void)toggleMessageWithText:(NSString *)text;
- (void)startLoadingIndicatorAnimation;
- (void)stopLoadingIndicatorAnimation;

@end
