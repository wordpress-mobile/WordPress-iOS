#import <UIKit/UIKit.h>

extern NSInteger const SuggestionsTableViewCellAvatarSize;

@interface SuggestionsTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UIImageView *avatarImageView;

@end
