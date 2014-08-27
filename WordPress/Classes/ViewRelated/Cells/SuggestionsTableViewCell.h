#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

extern const CGFloat SuggestionsTableViewCellAvatarSize;

@interface SuggestionsTableViewCell : WPTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@end
