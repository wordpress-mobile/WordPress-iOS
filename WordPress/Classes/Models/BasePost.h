#import <Foundation/Foundation.h>
#import "Blog.h"
#import "DateUtils.h"
#import "PostContentProvider.h"

NS_ASSUME_NONNULL_BEGIN

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

@interface BasePost : NSManagedObject<PostContentProvider>

// Attributes
@property (nonatomic, strong, nullable) NSNumber * postID;
@property (nonatomic, strong, nullable) NSNumber * authorID;
@property (nonatomic, strong, nullable) NSString * author;
@property (nonatomic, strong, nullable) NSString * authorAvatarURL;
@property (nonatomic, strong, nullable) NSDate * date_created_gmt;
@property (nonatomic, strong, nullable) NSString * postTitle;
@property (nonatomic, strong, nullable) NSString * content;
@property (nonatomic, strong, nullable) NSString * status;
@property (nonatomic, weak, readonly, nullable) NSString * statusTitle;
@property (nonatomic, strong, nullable) NSString * password;
@property (nonatomic, strong, nullable) NSString * permaLink;
@property (nonatomic, strong, nullable) NSString * mt_excerpt;
@property (nonatomic, strong, nullable) NSString * mt_text_more;
@property (nonatomic, strong, nullable) NSString * wp_slug;
@property (nonatomic, strong, nullable) NSNumber * remoteStatusNumber;
@property (nonatomic) AbstractPostRemoteStatus remoteStatus;
@property (nonatomic, strong, nullable) NSNumber * post_thumbnail;

// Helpers
/**
 Cached path of an image from the post to use for display purposes. 
 Not part of the post's canoncial data.
 */
@property (nonatomic, strong, nullable) NSString *pathForDisplayImage;
/**
 BOOL flag if the feature image was changed.
 */
@property (nonatomic, assign) BOOL isFeaturedImageChanged;

/**
 Returns the localized title for the specified status.  Status should be 
 one of the `PostStatus...` constants.  If a matching title is not found
 the status is returned. 
 
 @param string The post status value
 @return The localized title for the specified status, or the status if a title was not found.
*/
+ (NSString *)titleForStatus:(NSString *)status;

/**
 Create a summary for the post based on the post's content.

 @param string The post's content string. This should be the formatted content string.
 @return A summary for the post.
 */
+ (NSString *)summaryFromContent:(NSString *)string;

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
 Returns YES if the post has a future date_created_gmt.
 This is different from "isScheduled" in that  a post with a draft, pending, or 
 trashed status can also have a date_created_gmt with a future value.
 */
- (BOOL)hasFuturePublishDate;

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

//date conversion
- (nullable NSDate *)dateCreated;
- (void)setDateCreated:(nullable NSDate *)localDate;

//comments
- (void)findComments;

// Subclass methods
- (nullable NSString *)remoteStatusText;
+ (NSString *)titleForRemoteStatus:(nullable NSNumber *)remoteStatus;

@end

NS_ASSUME_NONNULL_END
