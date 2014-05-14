#import <UIKit/UIKit.h>

@interface NoteCommentPostBanner : UIControl

@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

- (void)setAvatarURL:(NSURL *)avatarURL;

@end
