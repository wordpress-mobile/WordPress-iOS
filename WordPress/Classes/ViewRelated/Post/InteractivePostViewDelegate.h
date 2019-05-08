@class AbstractPost;

/// Protocol that implements all delegate methods for InteractivePostView objects.
///
@protocol InteractivePostViewDelegate <NSObject>
@optional
- (void)handleEditPost:(nonnull AbstractPost *)post;
- (void)handleViewPost:(nonnull AbstractPost *)post;
- (void)handleStatsForPost:(nonnull AbstractPost *)post;
- (void)handleTrashPost:(nonnull AbstractPost *)post;
- (void)handlePublishPost:(nonnull AbstractPost *)post;
- (void)handleSchedulePost:(nonnull AbstractPost *)post;
- (void)handleRestorePost:(nonnull AbstractPost *)post;
- (void)handleDraftPost:(nonnull AbstractPost *)post;
@end
