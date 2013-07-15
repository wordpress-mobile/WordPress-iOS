//
//  Comment.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractComment.h"
#import "Blog.h"
#import "Post.h"

typedef enum {
	CommentStatusPending,
	CommentStatusApproved,
	CommentStatusDisapproved,
	CommentStatusSpam
} CommentStatus;

@interface Comment : AbstractComment {

}

@property (nonatomic, strong) Blog * blog;
@property (nonatomic, strong) AbstractPost * post;
@property (nonatomic, assign) BOOL isNew;

///-------------------------------------------
/// @name Creating and finding comment objects
///-------------------------------------------
+ (Comment *)findWithBlog:(Blog *)blog andCommentID:(NSNumber *)commentID;
// Takes the NSDictionary from a XMLRPC call and creates or updates a post
+ (Comment *)createOrReplaceFromDictionary:(NSDictionary *)commentInfo forBlog:(Blog *)blog;
- (Comment *)newReply;

///---------------------
/// @name Helper methods
///---------------------
+ (NSString *)titleForStatus:(NSString *)status;

///------------------------
/// @name Remote management
///------------------------
///
/// The following methods will change the comment on the WordPress site

/**
 Uploads a new reply or changes to an edited comment
 */
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/// Moderation
- (void)approve;
- (void)unapprove;
- (void)spam;
- (void)remove;

@end
