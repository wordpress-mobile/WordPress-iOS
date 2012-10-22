//
//  Comment.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Comment.h"

@interface Comment (PrivateMethods)
+ (Comment *)newCommentForBlog:(Blog *)blog;
- (void)moderate;
- (void)findPost;
- (void)save;
@end

@interface Comment (WordPressApi)
- (NSDictionary *)XMLRPCDictionary;
- (void)updateFromDictionary:(NSDictionary *)commentInfo;
- (void)postCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)getCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)editCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)deleteCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
@end


@implementation Comment
@dynamic author;
@dynamic author_email;
@dynamic author_ip;
@dynamic author_url;
@dynamic commentID;
@dynamic content;
@dynamic dateCreated;
@dynamic link;
@dynamic parentID;
@dynamic postID;
@dynamic postTitle;
@dynamic status;
@dynamic type;
@dynamic blog;
@dynamic post;
@synthesize isNew;

#pragma mark - Creating and finding comment objects

+ (Comment *)findWithBlog:(Blog *)blog andCommentID:(NSNumber *)commentID {
    NSSet *results = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID == %@",commentID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;    
}

+ (Comment *)createOrReplaceFromDictionary:(NSDictionary *)commentInfo forBlog:(Blog *)blog {
    if ([commentInfo objectForKey:@"comment_id"] == nil) {
        return nil;
    }
    
    Comment *comment = [self findWithBlog:blog andCommentID:[[commentInfo objectForKey:@"comment_id"] numericValue]];
    
    if (comment == nil) {
        comment = [Comment newCommentForBlog:blog];
        comment.isNew = YES;
    }
    
    [comment updateFromDictionary:commentInfo];
    [comment findPost];
    
    return comment;
}

- (Comment *)newReply {
    Comment *reply = [Comment newCommentForBlog:self.blog];
    reply.postID = self.postID;
    reply.post = self.post;
    reply.parentID = self.commentID;
    reply.status = @"approve";
    
    return reply;
}

#pragma mark - Helper methods

+ (NSString *)titleForStatus:(NSString *)status {
    if ([status isEqualToString:@"hold"]) {
        return NSLocalizedString(@"Pending moderation", @"");
    } else if ([status isEqualToString:@"approve"]) {
        return NSLocalizedString(@"Comments", @"");
    } else {
        return status;
    }

}

- (NSString *)postTitle {
	NSString *title = nil;
    if (self.post) {
        title = self.post.postTitle;
    } else {
        [self willAccessValueForKey:@"postTitle"];
        title = [self primitiveValueForKey:@"postTitle"];
        [self didAccessValueForKey:@"postTitle"];
    }

	if (title == nil || [@"" isEqualToString:title]) {
		title = NSLocalizedString(@"(no title)", @"the post has no title.");
	}
	return title;

}

- (NSString *)author {
	NSString *authorName = nil;

	[self willAccessValueForKey:@"author"];
	authorName = [self primitiveValueForKey:@"author"];
	[self didAccessValueForKey:@"author"];
	
	if (authorName == nil || [@"" isEqualToString:authorName]) {
		authorName = [NSLocalizedString(@"Anonymous", @"the comment has an anonymous author.") capitalizedString];
	}
	return authorName;
	
}

- (NSDate *)dateCreated {
	NSDate *date = nil;
	
	[self willAccessValueForKey:@"dateCreated"];
	date = [self primitiveValueForKey:@"dateCreated"];
	[self didAccessValueForKey:@"dateCreated"];
	
	if(date != nil)
		return [DateUtils GMTDateTolocalDate:date];
	else 
		return nil;
	
}

#pragma mark - Remote management

//this is used on reply and edit only
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    void (^uploadSuccessful)() = ^{
        [self getCommentWithSuccess:nil failure:nil];
        if (success) success();
    };

    if (self.commentID) {
        [self editCommentWithSuccess:uploadSuccessful failure:failure];
    } else {
        [self postCommentWithSuccess:uploadSuccessful failure:failure];
	}
}

- (void)approve {
	NSString *prevStatus = self.status;
	if([prevStatus isEqualToString:@"approve"])
		return;
	self.status = @"approve";
    [self editCommentWithSuccess:^(){
        [self save];
    } failure:^(NSError *error) {
        self.status = prevStatus;
        [self save];
    }];
}

- (void)unapprove {
	NSString *prevStatus = self.status;
	if([prevStatus isEqualToString:@"hold"])
    	return;
	self.status = @"hold";
    [self editCommentWithSuccess:^(){
        [self save];
    } failure:^(NSError *error) {
        self.status = prevStatus;
        [self save];
    }];
}

- (void)spam {
	NSString *prevStatus = self.status;
	if([prevStatus isEqualToString:@"spam"])
    	return;
    self.status = @"spam";
    [self editCommentWithSuccess:^(){
        [[self managedObjectContext] deleteObject:self];
        [self save];
    } failure:^(NSError *error) {
        self.status = prevStatus;
        [self save];
    }];
}

- (void)remove {
    if (self.commentID) {
        [self deleteCommentWithSuccess:nil failure:nil];
    }
    [[self managedObjectContext] deleteObject:self];
    [self save];
}

#pragma mark - Private Methods

+ (Comment *)newCommentForBlog:(Blog *)blog {
    Comment *comment = [[Comment alloc] initWithEntity:[NSEntityDescription entityForName:@"Comment"
                                                                   inManagedObjectContext:[blog managedObjectContext]]
                        insertIntoManagedObjectContext:[blog managedObjectContext]];
    
    comment.blog = blog;
    
    return comment;
}

- (void)findPost {
    if (self.post && self.postID && [self.post.postID isEqual:self.postID]) {
        return;
    }
	
	if(self.postID) {
        NSSet *posts = [self.blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@", self.postID]];
        
        if (posts && [posts count] > 0) {
            self.post = [posts anyObject];
        }
        
	}
}

- (void)save {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

@end

@implementation Comment (WordPressApi)

- (NSDictionary *)XMLRPCDictionary {
    NSMutableDictionary *commentParams = [NSMutableDictionary dictionary];

	if(self.content != nil)
		[commentParams setObject:self.content forKey:@"content"];
	else 
		[commentParams setObject:@"" forKey:@"content"];

    //keep attention. getComment, getComments are returning a different key "parent" that is a string.
    [commentParams setObject:self.parentID forKey:@"comment_parent"];
    [commentParams setObject:self.postID forKey:@"post_id"];
    [commentParams setObject:self.status forKey:@"status"];

    return commentParams;
}

- (void)updateFromDictionary:(NSDictionary *)commentInfo {
    self.author          = [commentInfo objectForKey:@"author"];
    self.author_email    = [commentInfo objectForKey:@"author_email"];
    self.author_url      = [commentInfo objectForKey:@"author_url"];
    self.commentID       = [[commentInfo objectForKey:@"comment_id"] numericValue];
    self.content         = [commentInfo objectForKey:@"content"];
    self.dateCreated     = [commentInfo objectForKey:@"date_created_gmt"];
    self.link            = [commentInfo objectForKey:@"link"];
    self.parentID        = [[commentInfo objectForKey:@"parent"] numericValue];
    self.postID          = [[commentInfo objectForKey:@"post_id"] numericValue];
    self.postTitle       = [commentInfo objectForKey:@"post_title"];
    self.status          = [commentInfo objectForKey:@"status"];
    self.type            = [commentInfo objectForKey:@"type"];    
}

- (void)postCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:[NSArray arrayWithObjects:self.postID, [self XMLRPCDictionary], nil]];
    [self.blog.api callMethod:@"wp.newComment"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          // wp.newComment should return an integer with the new comment ID
                          if ([responseObject respondsToSelector:@selector(numericValue)]) {
                              self.commentID = [responseObject numericValue];
                              [self save];
                              if (success) success();
                          } else if (failure) {
                              NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid value returned for new comment: %@", responseObject] forKey:NSLocalizedDescriptionKey];
                              NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
                              failure(error);
                          }
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)getCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:self.commentID];
    [self.blog.api callMethod:@"wp.getComment"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          [self updateFromDictionary:responseObject];
                          if (success) success();
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)editCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (self.commentID == nil) {
        if (failure) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Can't edit a comment if it's not in the server" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
            failure(error);
        }
        return;
    }

    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:[NSArray arrayWithObjects:self.commentID, [self XMLRPCDictionary], nil]];
    [self.blog.api callMethod:@"wp.editComment"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          // wp.editComment should return true if the edit was successful
                          if (success) success();
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)deleteCommentWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (self.commentID == nil) {
        if (failure) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Can't delete a comment if it's not in the server" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
            failure(error);
        }
        return;
    }
    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:self.commentID];
    [self.blog.api callMethod:@"wp.deleteComment"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          // wp.deleteComment should return true if the edit was successful
                          [[self managedObjectContext] deleteObject:self];
                          if (success) success();
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) failure(error);
                      }];
}

@end
