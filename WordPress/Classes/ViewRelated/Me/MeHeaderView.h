#import <UIKit/UIKit.h>

extern const CGFloat MeHeaderViewHeight;

@interface MeHeaderView : UIView

- (void)setDisplayName:(NSString*)displayname;
- (void)setUsername:(NSString *)username;
- (void)setGravatarEmail:(NSString *)gravatarEmail;

@end
