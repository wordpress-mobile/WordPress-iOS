//
//  Comment.h
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blog.h"
#import "Post.h"

typedef enum {
	CommentStatusPending,
	CommentStatusApproved,
	CommentStatusDisapproved,
	CommentStatusSpam
} CommentStatus;

@interface Comment : NSManagedObject {

}
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * author_email;
@property (nonatomic, retain) NSString * author_ip;
@property (nonatomic, retain) NSString * author_url;
@property (nonatomic, retain) NSNumber * commentID;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSNumber * parentID;
@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSString * postTitle;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Blog * blog;
@property (nonatomic, retain) AbstractPost * post;

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
