#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

typedef void (^NotificationsFollowBlock)(id sender);

@interface NotificationsFollowTableViewCell : WPTableViewCell

@property (nonatomic, copy)	  NotificationsFollowBlock	onClick;
@property (nonatomic, strong) UIButton					*actionButton;
@property (nonatomic, assign) BOOL						following;

@end
