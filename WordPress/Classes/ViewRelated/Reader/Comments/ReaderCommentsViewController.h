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
    ReaderCommentsSourceActivityLogDetail
};

@class RemoteComment;
@class ReaderPost;

@interface ReaderCommentsViewController : UIViewController

@property (nonatomic, strong, readonly) ReaderPost *post;
@property (nonatomic, assign, readwrite) BOOL allowsPushingPostDetails;
@property (nonatomic, assign, readwrite) ReaderCommentsSource source;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)controllerWithPost:(ReaderPost *)post source:(ReaderCommentsSource)source;
+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID source:(ReaderCommentsSource)source;

/// Opens the Add Comment when the view appears
@property (nonatomic) BOOL promptToAddComment;
/// Navigates to the specified comment when the view appears
@property (nonatomic, strong) NSNumber *navigateToCommentID;



// Undo comment moderation support.
// These are public so they can be accessed from the Swift extension.
@property (nonatomic, strong, readwrite) RemoteComment *commentPendingUndo;
@property (nonatomic, readwrite) NSInteger pendingCommentDepth;
@property (nonatomic, strong, readwrite) NSString *pendingCommentHierarchy;
- (void)refreshTableViewAndNoResultsView;

@end
