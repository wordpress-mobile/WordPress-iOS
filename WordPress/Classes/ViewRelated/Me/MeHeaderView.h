#import <UIKit/UIKit.h>

extern const CGFloat MeHeaderViewHeight;

@interface MeHeaderView : UIView

@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *gravatarEmail;

@end
