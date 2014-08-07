#import "WPNoResultsView.h"


@interface WPNoResultsView (AnimatedBox)

+ (void)displayAnimatedBoxWithTitle:(NSString *)title message:(NSString *)message view:(UIView *)view;
+ (void)removeFromView:(UIView *)view;

@end
