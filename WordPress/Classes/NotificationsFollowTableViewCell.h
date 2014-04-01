#import <UIKit/UIKit.h>

@interface NotificationsFollowTableViewCell : UITableViewCell

@property (nonatomic, strong) UIButton *actionButton;

- (void)setFollowing: (BOOL)isFollowing;

@end


