#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"

NS_ASSUME_NONNULL_BEGIN

@class Media;
@class Comment;

typedef enum {
    AbstractPostRemoteStatusPushing,    // Uploading post
    AbstractPostRemoteStatusFailed,      // Upload failed
    AbstractPostRemoteStatusLocal,       // Only local version
    AbstractPostRemoteStatusSync,       // Post uploaded
} AbstractPostRemoteStatus;

extern NSString * const PostStatusDraft;
extern NSString * const PostStatusPending;
extern NSString * const PostStatusPrivate;
extern NSString * const PostStatusPublish;
extern NSString * const PostStatusScheduled;
extern NSString * const PostStatusTrash;
extern NSString * const PostStatusDeleted;

@interface AbstractPost : BasePost

// Relationships
@property (nonatomic, strong) Blog *blog;
/**
 The dateModified field is used in tandem with date_created_gmt to determine if
 a draft post should be published immediately. A draft post will "publish immediately"
 when the date_created_gmt and the modified date match.
 */
@property (nonatomic, strong, nullable) NSDate * dateModified;
@property (nonatomic, strong) NSSet *media;
@property (weak, readonly) AbstractPost *original;
@property (weak, readonly) AbstractPost *revision;
@property (nonatomic, strong) NSSet *comments;
@property (nonatomic, strong, nullable) Media *featuredImage;

// By convention these should be treated as read only and not manually set.
// These are primarily used as helpers sorting fetchRequests.
@property (nonatomic, assign) BOOL metaIsLocal;
@property (nonatomic, assign) BOOL metaPublishImmediately;
@property (nonatomic) AbstractPostRemoteStatus remoteStatus;
@property (nonatomic, readonly) BOOL hasBeenPublished;

/**
 Used to store the post's status before its sent to the trash.
 */
@property (nonatomic, strong) NSString *restorableStatus;
@property (nonatomic, weak, readonly, nullable) NSString * statusTitle;

// Revision management
- (AbstractPost *)createRevision;
- (void)deleteRevision;
- (void)applyRevision;
- (void)updateRevision;
- (BOOL)isRevision;
- (BOOL)isOriginal;

/// Returns the latest revision of a post.
///
- (AbstractPost *)latest;
- (void)cloneFrom:(AbstractPost *)source;
- (BOOL)hasSiteSpecificChanges;
- (BOOL)hasPhoto;
- (BOOL)hasVideo;
- (BOOL)hasCategories;
- (BOOL)hasTags;

/**
 *  @brief      Call this method to know whether this post has a revision or not.
 *
 *  @returns    YES if this post has a revision, NO otherwise.
 */
- (BOOL)hasRevision;

#pragma mark - Conveniece Methods
- (void)publish;
- (void)publishImmediately;
- (BOOL)shouldPublishImmediately;
- (NSString *)authorNameForDisplay;
- (NSString *)blavatarForDisplay;
- (NSString *)dateStringForDisplay;
- (BOOL)isMultiAuthorBlog;
- (BOOL)isPrivate;
- (BOOL)supportsStats;


#pragma mark - Unsaved Changes

/**
 *  @brief      Wether the post can be saved or not.
 *
 *  @returns    YES if the post can be saved, NO otherwise.
 */
- (BOOL)canSave;

/**
 *  @brief      Call this method to know if the post has either local or remote unsaved changes.
 *  @details    There should be no need to override this method.  Consider overriding
 *              methods hasLocalChanges and hasRemoteChanges instead.
 *  @returns    YES if there are unsaved changes, NO otherwise.
 */
- (BOOL)hasUnsavedChanges;

/**
 *  @brief      Call this method to know if the post has remote changes.
 *  @returns    YES if there are unsaved changes, NO otherwise.
 */
- (BOOL)hasRemoteChanges;



/**
 Returns the localized title for the specified status.  Status should be
 one of the `PostStatus...` constants.  If a matching title is not found
 the status is returned.

 @param string The post status value
 @return The localized title for the specified status, or the status if a title was not found.
 */
+ (NSString *)titleForStatus:(NSString *)status;

/**
 An array of statuses available to a post while editing
 @details Subset of status a user may assign to a post they are editing.
 Status included are: draft, pending, and publish.
 Private is not listed as this is determined by the visibility settings.
 Scheduled is not listed as this should be handled by assigning a
 future date.
 Trash is not listed as this should be handled via a delete action.
 */
- (NSArray *)availableStatusesForEditing;


/**
 Returns the correct "publish" status for the current value of date_created_gmt.
 Future dates return PostStatusScheduled. Otherwise PostStatusPublish. This is not
 necessarily the current value of `status`
 */
- (NSString *)availableStatusForPublishOrScheduled;

/**
 Returns YES if the post is has a `future` post status
 */
- (BOOL)isScheduled;

/**
 Returns YES if the post is a draft
 */
- (BOOL)isDraft;

/**
 Returns YES if the post has a future date_created_gmt.
 This is different from "isScheduled" in that  a post with a draft, pending, or
 trashed status can also have a date_created_gmt with a future value.
 */
- (BOOL)hasFuturePublishDate;

/**
 Returns YES if dateCreated is nil, or if dateCreated and dateModified are equal.
 Used when determining if a post should publish immediately.
 */
- (BOOL)dateCreatedIsNilOrEqualToDateModified;

/**
 *  Whether there was any attempt ever to upload this post, either successful or failed.
 *
 *  @returns    YES if there ever was an attempt to upload this post, NO otherwise.
 */
- (BOOL)hasNeverAttemptedToUpload;

/**
 *  Whether the post has local changes or not.  Local changes are all changes that are have not been
 *  published to the server yet.
 *
 *  @returns    YES if the post has local changes, NO otherwise.
 */
- (BOOL)hasLocalChanges;

// Does the post exist on the blog?
- (BOOL)hasRemote;
// Deletes post locally
- (void)remove;
// Save changes to disk
- (void)save;

// Subclass methods
- (nullable NSString *)remoteStatusText;
+ (NSString *)titleForRemoteStatus:(nullable NSNumber *)remoteStatus;

@end

@interface AbstractPost (CoreDataGeneratedAccessors)

- (void)addMediaObject:(Media *)value;
- (void)removeMediaObject:(Media *)value;
- (void)addMedia:(NSSet *)values;
- (void)removeMedia:(NSSet *)values;

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
