#import <UIKit/UIKit.h>

// Used for event tracking source property
// to track where comments are viewed from.
typedef NS_ENUM(NSUInteger, ReaderCommentsSource) {
    ReaderCommentsSourcePostCard,
    ReaderCommentsSourcePostDetails,
    ReaderCommentsSourcePostDetailsComments,
    ReaderCommentsSourceCommentNotification,
    ReaderCommentsSourceCommentLikeNotification,
    ReaderCommentsSourceMySiteComment,
    ReaderCommentsSourceActivityLogDetail,
    ReaderCommentsSourcePostsList
};

@class Comment;
@class CommentCellViewModel;
@class CommentContentTableViewCell;
@class ReaderPost;
@class ReaderCommentsHelper;

@interface ReaderCommentsViewController : UIViewController

@property (nonatomic, strong, readonly) ReaderPost *post;
@property (nonatomic, assign, readwrite) BOOL allowsPushingPostDetails;
@property (nonatomic, assign, readwrite) ReaderCommentsSource source;
@property (nonatomic, strong, readonly) ReaderCommentsHelper *helper;
@property (nonatomic, strong, readonly) UIView *buttonAddComment;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)controllerWithPost:(ReaderPost *)post source:(ReaderCommentsSource)source;
+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID source:(ReaderCommentsSource)source;

/// Navigates to the specified comment when the view appears
@property (nonatomic, strong) NSNumber *navigateToCommentID;


// Comment moderation support.
@property (nonatomic, assign, readwrite) BOOL commentModified;
- (void)refreshAfterCommentModeration;
- (void)trackReplyTo:(BOOL)replyTarget;
- (void)configureCell:(CommentContentTableViewCell *)cell viewModel:(CommentCellViewModel *)viewModel indexPath:(NSIndexPath *)indexPath;
- (UIView *)cachedHeaderView;
- (void)loadMore;
- (void)highlightCommentAtIndexPath:(NSIndexPath *)indexPath;

@end
