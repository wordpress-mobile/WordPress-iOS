#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <WordPressData/BasePost.h>

NS_ASSUME_NONNULL_BEGIN

@class Media;
@class Comment;

typedef NS_ENUM(NSUInteger, AbstractPostRemoteStatus) {
    AbstractPostRemoteStatusPushing,    // Uploading post
    AbstractPostRemoteStatusFailed,      // Upload failed
    AbstractPostRemoteStatusLocal,       // Only local version
    AbstractPostRemoteStatusSync,       // Post uploaded
    AbstractPostRemoteStatusPushingMedia, // Push Media
    AbstractPostRemoteStatusAutoSaved,       // Post remote auto-saved

    // All the previous states were deprecated in 24.9 and are no longer used
    // by the app. To get the status of the uploads, use `PostCoordinator`.

    /// The default state of the newly created local revision.
    AbstractPostRemoteStatusLocalRevision,
    /// The user saved the revision, and it needs to be uploaded to a server.
    AbstractPostRemoteStatusSyncNeeded
};

@interface AbstractPost : BasePost

// Relationships
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong, nullable) NSDate * dateModified;
@property (nonatomic, strong) NSSet<Media *> *media;
@property (weak, readonly) AbstractPost *original;
@property (weak, readonly) AbstractPost *revision;
@property (nonatomic, strong) NSSet *comments;
@property (nonatomic, strong, nullable) Media *featuredImage;
@property (nonatomic, assign) NSInteger order;

/// This array will contain a list of revision IDs.
@property (nonatomic, strong, nullable) NSArray *revisions;
/// The default value of autoUploadAttemptsCount is 0.
@property (nonatomic, strong, nonnull) NSNumber *autoUploadAttemptsCount;

/// Autosave attributes hold a snapshot of the post's content.
@property (nonatomic, copy, nullable) NSString *autosaveContent;
@property (nonatomic, copy, nullable) NSString *autosaveExcerpt;
@property (nonatomic, copy, nullable) NSString *autosaveTitle;
@property (nonatomic, copy, nullable) NSDate *autosaveModifiedDate;
@property (nonatomic, copy, nullable) NSNumber *autosaveIdentifier;

/// Used to deduplicate new posts
@property (nonatomic, strong, nullable) NSUUID *foreignID;

@property (nonatomic, strong, nullable) NSDate *confirmedChangesTimestamp;

@property (nonatomic, strong, nullable) NSString *voiceContent;

// Revision management
- (AbstractPost *)createRevision;
- (void)deleteRevision;
- (void)applyRevision;
- (AbstractPost *)updatePostFrom:(AbstractPost *)revision;
- (BOOL)isRevision;
- (BOOL)isOriginal;

/// Returns the latest revision of a post.
///
- (AbstractPost *)latest;
- (AbstractPost *)cloneFrom:(AbstractPost *)source;
- (BOOL)hasPhoto;
- (BOOL)hasVideo;
- (BOOL)hasCategories;
- (BOOL)hasTags;

@property (nonatomic, assign, readonly) BOOL hasFailedMedia;

/**
 *  @brief      Call this method to know whether this post has a revision or not.
 *
 *  @returns    YES if this post has a revision, NO otherwise.
 */
- (BOOL)hasRevision;

#pragma mark - Conveniece Methods
- (BOOL)shouldPublishImmediately;
- (NSString *)authorNameForDisplay;
- (NSString *)blavatarForDisplay;
- (NSString *)dateStringForDisplay;
- (BOOL)isPrivateAtWPCom;


#pragma mark - Unsaved Changes

/**
 Returns YES if the post is has a `future` post status
 */
- (BOOL)isScheduled;

/**
 Returns YES if the post is a draft
 */
- (BOOL)isDraft;

/**
 Returns YES if the post is a published.
 */
- (BOOL)isPublished;

/**
 Returns YES if the original post is a draft
 */
- (BOOL)originalIsDraft;

// Does the post exist on the blog?
- (BOOL)hasRemote;

// Save changes to disk
- (void)save;

/**
 * Updates the path for the display image by looking at the post content and trying to find an good image to use.
 * If no appropiated image is found the path is set to nil.
 */
- (void)updatePathForDisplayImageBasedOnContent;

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
