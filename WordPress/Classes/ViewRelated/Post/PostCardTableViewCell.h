#import <UIKit/UIKit.h>
#import "WPPostContentViewProvider.h"

@interface PostCardTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIView *shadowView;
@property (nonatomic, strong) IBOutlet UIView *postContentView;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *authorLabel;
@property (nonatomic, strong) IBOutlet UIImageView *featuredImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *snippetLabel;
@property (nonatomic, strong) IBOutlet UIView *dateView;
@property (nonatomic, strong) IBOutlet UIImageView *dateImageView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *statusView;
@property (nonatomic, strong) IBOutlet UIImageView *statusImageView;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIView *metaView;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonRight;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonCenter;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonLeft;
@property (nonatomic, strong) IBOutlet UIView *actionBar;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *avatarImageViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *snippetLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *dateViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *wrapperViewLowerConstraint;

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider;

@end
