#import "NoteBlockUserTableViewCell.h"
#import "Notification.h"

#import "WPStyleGuide+Notifications.h"

#import <AFNetworking/UIImageView+AFNetworking.h>



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static CGFloat NotificationBlockFollowCellHeight                = 80.0f;
static NSTimeInterval const NotificationAnimationDuration       = 0.3f;
static NSTimeInterval const NotificationAnimationAlphaInitial   = 0.5f;
static NSTimeInterval const NotificationAnimationAlphaFinal     = 1.0f;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteBlockUserTableViewCell ()
@property (nonatomic, weak) IBOutlet UIImageView    *gravatarImageView;
@property (nonatomic, weak) IBOutlet UILabel        *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel        *blogLabel;
@property (nonatomic, weak) IBOutlet UIButton       *followButton;
@end


#pragma mark ====================================================================================
#pragma mark NoteBlockFollowTableViewCell
#pragma mark ====================================================================================

@implementation NoteBlockUserTableViewCell

- (void)awakeFromNib
{
    [WPStyleGuide configureFollowButton:self.followButton];
 
    self.backgroundColor                        = [WPStyleGuide notificationBlockBackgroundColor];
    
    self.nameLabel.textColor                    = [WPStyleGuide littleEddieGrey];
    self.nameLabel.font                         = [WPStyleGuide tableviewSectionHeaderFont];
    
    self.blogLabel.font                         = [WPStyleGuide subtitleFont];
    self.blogLabel.textColor                    = [WPStyleGuide baseDarkerBlue];
    self.blogLabel.adjustsFontSizeToFitWidth    = NO;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    self.followButton.highlighted = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animate
{
    [super setSelected:selected animated:animate];
    self.followButton.highlighted = NO;
}

- (void)setFollowing:(BOOL)isFollowing
{
    [_followButton setSelected:isFollowing];
	_following = isFollowing;
}


#pragma mark NoteBlockRender methods

- (void)setName:(NSString *)name
{
    self.nameLabel.text = name;
    _name = name;
}

- (void)setBlogURL:(NSURL *)blogURL
{
    self.blogLabel.text = blogURL.host;
    self.accessoryType  = blogURL ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    _blogURL = blogURL;
}

- (void)setGravatarURL:(NSURL *)gravatarURL
{
    if ([gravatarURL isEqual:_gravatarURL]) {
        return;
    }
    
    [self downloadImageWithURL:gravatarURL];
    _gravatarURL = gravatarURL;
}

- (void)setActionEnabled:(BOOL)actionEnabled
{
    self.followButton.hidden = !actionEnabled;
    _actionEnabled = actionEnabled;
}


#pragma mark - Image Helpers

- (void)downloadImageWithURL:(NSURL *)url
{
    __weak __typeof(self) weakSelf  = self;
    NSMutableURLRequest *request	= [NSMutableURLRequest requestWithURL:url];
    request.HTTPShouldHandleCookies = NO;
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    [self.gravatarImageView setImageWithURLRequest:request
                           placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        [weakSelf displayImage:image];
                                    }
                                    failure:nil
     ];
}

- (void)displayImage:(UIImage *)image
{
    if (!image) {
        return;
    }
    
    _gravatarImageView.image    = image;
    _gravatarImageView.alpha    = NotificationAnimationAlphaInitial;
    
    [UIView animateWithDuration:NotificationAnimationDuration animations:^{
        _gravatarImageView.alpha = NotificationAnimationAlphaFinal;
    }];
}


#pragma mark Button Delegates

- (IBAction)followWasPressed:(id)sender
{
    if (!self.onFollowClick) {
        return;
    }
    
    self.following = !_following;
    self.onFollowClick();
}


#pragma mark - NoteBlockTableViewCell Methods

+ (CGFloat)heightWithText:(NSString *)text
{
    return NotificationBlockFollowCellHeight;
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
