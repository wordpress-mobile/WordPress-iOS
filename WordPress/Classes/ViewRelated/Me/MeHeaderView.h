#import <UIKit/UIKit.h>

extern const CGFloat MeHeaderViewHeight;

@interface MeHeaderView : UIView

- (void)setUsername:(NSString *)username;
- (void)setGravatarEmail:(NSString *)gravatarEmail;

@end
