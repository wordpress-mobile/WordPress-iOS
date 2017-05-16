@class AbstractPost;

/// Protocol that implements all delegate methods for InteractivePostView objects.
///
@protocol InteractivePostViewDelegate <NSObject>
@optional
- (void)cell:(nonnull UITableViewCell *)cell handleEditPost:(nonnull AbstractPost *)post;
- (void)cell:(nonnull UITableViewCell *)cell handleViewPost:(nonnull AbstractPost *)post;
- (void)cell:(nonnull UITableViewCell *)cell handleStatsForPost:(nonnull AbstractPost *)post;
- (void)cell:(nonnull UITableViewCell *)cell handleTrashPost:(nonnull AbstractPost *)post;
- (void)cell:(nonnull UITableViewCell *)cell handlePublishPost:(nonnull AbstractPost *)post;
- (void)cell:(nonnull UITableViewCell *)cell handleSchedulePost:(nonnull AbstractPost *)post;
- (void)cell:(nonnull UITableViewCell *)cell handleRestorePost:(nonnull AbstractPost *)post;
@end
