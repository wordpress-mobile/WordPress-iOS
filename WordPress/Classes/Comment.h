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
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * author_email;
@property (nonatomic, strong) NSString * author_ip;
@property (nonatomic, strong) NSString * author_url;
@property (nonatomic, strong) NSNumber * commentID;
@property (nonatomic, strong) NSString * content;
@property (nonatomic, strong) NSDate * dateCreated;
@property (nonatomic, strong) NSString * link;
@property (nonatomic, strong) NSNumber * parentID;
@property (nonatomic, strong) NSNumber * postID;
@property (nonatomic, strong) NSString * postTitle;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, strong) NSString * type;
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
