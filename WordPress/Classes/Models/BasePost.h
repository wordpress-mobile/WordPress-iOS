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

@interface BasePost : NSManagedObject<WPContentViewProvider> {

}

// Attributes
@property (nonatomic, strong) NSNumber * postID;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * authorAvatarURL;
@property (nonatomic, strong) NSDate * date_created_gmt;
@property (nonatomic, strong) NSString * postTitle;
@property (nonatomic, strong) NSString * content;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, weak) NSString * statusTitle;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSString * permaLink;
@property (nonatomic, strong) NSString * mt_excerpt;
@property (nonatomic, strong) NSString * mt_text_more;
@property (nonatomic, strong) NSString * wp_slug;
@property (nonatomic, strong) NSNumber * remoteStatusNumber;
@property (nonatomic) AbstractPostRemoteStatus remoteStatus;
@property (nonatomic, strong) NSNumber * post_thumbnail;

@property (nonatomic, assign) BOOL isFeaturedImageChanged;

- (NSArray *)availableStatuses;

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

#pragma mark - Status

/**
 *  @brief      Call this method to know if the post is a draft.
 *
 *  @returns    YES if the post is a draft.  NO otherwise.
 */
- (BOOL)isDraft;

/**
 *  @brief      Call this method to know if the post is pending review.
 *
 *  @returns    YES if the post is pending review.  NO otherwise.
 */
- (BOOL)isPending;

/**
 *  @brief      Call this method to know if the post is published.
 *
 *  @returns    YES if the post is published.  NO otherwise.
 */
- (BOOL)isPublished;

/**
 *  @brief      Call this method to know if the post is private.
 *
 *  @returns    YES if the post is private.  NO otherwise.
 */
- (BOOL)isPrivate;

/**
 *  @brief      Call this method to know if the post is scheduled for publishing.
 *  @details    This returns YES whether the scheduled publishing date is immediate or future.
 *
 *  @returns    YES if the post is scheduled for publishing.  NO otherwise.
 */
- (BOOL)isScheduled;

/**
 *  @brief      Call this method to know if the post is scheduled for immediate publishing.
 *
 *  @returns    YES if the post is scheduled for immediate publishing.  NO otherwise.
 */
- (BOOL)isScheduledForImmediatePublishing;

/**
 *  @brief      Call this method to know if the post is scheduled for future publishing.
 *
 *  @returns    YES if the post is scheduled for future publishing.  NO otherwise.
 */
- (BOOL)isScheduledForFuturePublishing;

@end
