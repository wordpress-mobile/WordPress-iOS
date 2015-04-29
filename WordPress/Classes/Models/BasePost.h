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

extern NSString *const BasePostStatusDraft;
extern NSString *const BasePostStatusPending;
extern NSString *const BasePostStatusPrivate;
extern NSString *const BasePostStatusPublished;

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
