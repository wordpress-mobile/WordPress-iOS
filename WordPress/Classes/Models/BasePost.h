#import <Foundation/Foundation.h>
#import "Blog.h"
#import "DateUtils.h"
#import "WPContentViewProvider.h"

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

@interface BasePost : NSManagedObject<WPContentViewProvider>

// Attributes
@property (nonatomic, strong) NSNumber * postID;
@property (nonatomic, strong) NSNumber * authorID;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * authorAvatarURL;
@property (nonatomic, strong) NSDate * date_created_gmt;
@property (nonatomic, strong) NSString * postTitle;
@property (nonatomic, strong) NSString * content;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, weak, readonly) NSString * statusTitle;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSString * permaLink;
@property (nonatomic, strong) NSString * mt_excerpt;
@property (nonatomic, strong) NSString * mt_text_more;
@property (nonatomic, strong) NSString * wp_slug;
@property (nonatomic, strong) NSNumber * remoteStatusNumber;
@property (nonatomic) AbstractPostRemoteStatus remoteStatus;
@property (nonatomic, strong) NSNumber * post_thumbnail;

// Helpers
/**
 Cached path of an image from the post to use for display purposes. 
 Not part of the post's canoncial data.
 */
@property (nonatomic, strong) NSString *pathForDisplayImage;
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
 Returns YES if the post is scheduled to be published on a specific date in the future.
 */
- (BOOL)isScheduled;

// Does the post exist on the blog?
- (BOOL)hasRemote;
// Deletes post locally
- (void)remove;
// Save changes to disk
- (void)save;

//date conversion
- (NSDate *)dateCreated;
- (void)setDateCreated:(NSDate *)localDate;

//comments
- (void)findComments;

// Subclass methods
- (NSString *)remoteStatusText;
+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus;

@end
