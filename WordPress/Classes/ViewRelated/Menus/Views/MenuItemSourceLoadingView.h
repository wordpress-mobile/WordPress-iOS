#import <UIKit/UIKit.h>

@interface MenuItemSourceLoadingView : UIView

@property (nonatomic, assign) BOOL isAnimating;

- (void)startAnimating;
- (void)stopAnimating;

@end
