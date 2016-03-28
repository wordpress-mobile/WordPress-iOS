#import <UIKit/UIKit.h>

extern const CGFloat MeHeaderViewHeight;
typedef void (^MeHeaderViewCallback)(void);

@interface MeHeaderView : UIView

@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *gravatarEmail;
@property (nonatomic, copy) MeHeaderViewCallback onPress;

- (void)startActivityIndicator;
- (void)stopActivityIndicator;

@end
