#import <Foundation/Foundation.h>
#import "AbstractComment.h"
#import "Blog.h"
#import "Post.h"

// This is the notification name used with NSNotificationCenter
extern NSString * const CommentUploadFailedNotification;

extern NSString * const CommentStatusPending;
extern NSString * const CommentStatusApproved;
extern NSString * const CommentStatusDisapproved;
extern NSString * const CommentStatusSpam;
// Draft status is for comments that have not yet been successfully published
// we can use this status to restore comment replies that the user has written
extern NSString * const CommentStatusDraft;

@interface Comment : AbstractComment {

}

@property (nonatomic, strong) Blog * blog;
@property (nonatomic, strong) AbstractPost * post;
@property (nonatomic, assign) BOOL isNew;

///-------------------------------------------
/// @name Creating and finding comment objects
///-------------------------------------------

+ (void)mergeNewComments:(NSArray *)newComments forBlog:(Blog *)blog;

///---------------------
/// @name Helper methods
///---------------------
+ (NSString *)titleForStatus:(NSString *)status;

///------------------------
/// @name Remote management
///------------------------
///
/// The following methods will change the comment on the WordPress site

/// Moderation
- (void)approve;
- (void)unapprove;
- (void)spam;
- (void)remove;

@end
