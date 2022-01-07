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

@end
