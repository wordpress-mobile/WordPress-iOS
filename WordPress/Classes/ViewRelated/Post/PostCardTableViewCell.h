#import <UIKit/UIKit.h>
#import "PostCardActionBar.h"
#import "WPPostContentViewProvider.h"

@protocol PostCardTableViewCellDelegate;

@interface PostCardTableViewCell : UITableViewCell

@property (nonatomic, weak) id<PostCardTableViewCellDelegate>delegate;
@property (nonatomic, strong) IBOutlet UIView *innerContentView;
@property (nonatomic, strong) IBOutlet UIView *shadowView;
@property (nonatomic, strong) IBOutlet UIView *postContentView;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *authorBlogLabel;
@property (nonatomic, strong) IBOutlet UILabel *authorNameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *postCardImageView;
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
@property (nonatomic, strong) IBOutlet UIButton *metaButtonLeft;
@property (nonatomic, strong) IBOutlet PostCardActionBar *actionBar;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *snippetLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *dateViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postContentBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *maxIPadWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postCardImageViewBottomConstraint;

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider;

@end


@protocol PostCardTableViewCellDelegate <NSObject>
@optional
- (void)cell:(PostCardTableViewCell *)cell receivedEditActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedViewActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedStatsActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedTrashActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedPublishActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(PostCardTableViewCell *)cell receivedRestoreActionForProvider:(id<WPPostContentViewProvider>)contentProvider;
@end
