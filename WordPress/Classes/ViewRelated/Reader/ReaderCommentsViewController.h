#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderCommentsViewController : UIViewController

@property (nonatomic, strong, readonly) ReaderPost *post;
@property (nonatomic, assign, readwrite) BOOL allowsPushingPostDetails;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)controllerWithPost:(ReaderPost *)post;
+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

/// Opens the Add Comment when the view appears
@property (nonatomic) BOOL promptToAddComment;
/// Navigates to the specified comment when the view appears
@property (nonatomic, strong) NSNumber *navigateToCommentID;

@end
