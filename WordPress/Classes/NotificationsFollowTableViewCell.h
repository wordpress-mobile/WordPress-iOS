#import <UIKit/UIKit.h>

typedef void (^NotificationsFollowBlock)(id sender);

@interface NotificationsFollowTableViewCell : UITableViewCell

@property (nonatomic, copy)	  NotificationsFollowBlock	onClick;
@property (nonatomic, strong) UIButton					*actionButton;
@property (nonatomic, assign) BOOL						following;

@end
