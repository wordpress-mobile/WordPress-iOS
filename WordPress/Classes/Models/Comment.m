#import "Comment.h"
#import "ContextManager.h"

NSString * const CommentUploadFailedNotification = @"CommentUploadFailed";

NSString * const CommentStatusPending = @"hold";
NSString * const CommentStatusApproved = @"approve";
NSString * const CommentStatusDisapproved = @"trash";
NSString * const CommentStatusSpam = @"spam";

// draft is used for comments that have been composed but not succesfully uploaded yet
NSString * const CommentStatusDraft = @"draft";

@interface Comment (WordPressApi)
- (void)updateFromDictionary:(NSDictionary *)commentInfo;
@end


@implementation Comment
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
    [comment findPostWithContext:blog.managedObjectContext];
    
    return comment;
}

+ (void)mergeNewComments:(NSArray *)newComments forBlog:(Blog *)blog {
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] newDerivedContext];
    [backgroundMOC performBlock:^{
        NSMutableArray *commentsToKeep = [NSMutableArray array];
        Blog *contextBlog = (Blog *)[backgroundMOC existingObjectWithID:blog.objectID error:nil];
        
        for (NSDictionary *commentInfo in newComments) {
            Comment *newComment = [Comment createOrReplaceFromDictionary:commentInfo forBlog:contextBlog];
            if (newComment != nil) {
                [commentsToKeep addObject:newComment];
            } else {
                DDLogInfo(@"-[Comment createOrReplaceFromDictionary:forBlog:] returned a nil comment: %@", commentInfo);
            }
        }
        
        NSSet *existingComments = contextBlog.comments;
        if (existingComments && (existingComments.count > 0)) {
            for (Comment *comment in existingComments) {
                // Don't delete unpublished comments
                if(![commentsToKeep containsObject:comment] && comment.commentID != nil) {
                    DDLogInfo(@"Deleting Comment: %@", comment);
                    [backgroundMOC deleteObject:comment];
                }
            }
        }
        
        [[ContextManager sharedInstance] saveDerivedContext:backgroundMOC];
    }];
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
		authorName = NSLocalizedString(@"Anonymous", @"the comment has an anonymous author.");
	}
	return authorName;
	
}

- (NSDate *)dateCreated {
	NSDate *date = nil;
	
	[self willAccessValueForKey:@"dateCreated"];
	date = [self primitiveValueForKey:@"dateCreated"];
	[self didAccessValueForKey:@"dateCreated"];
	
    return date;
}

#pragma mark - Private Methods

+ (Comment *)newCommentForBlog:(Blog *)blog {
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:blog.managedObjectContext];
    comment.blog = blog;
    return comment;
}

- (void)findPostWithContext:(NSManagedObjectContext *)context {
    Post *contextPost;
    if (self.post) {
        contextPost = (Post*)[context objectWithID:self.post.objectID];
    }
    Blog *contextBlog = (Blog*)[context objectWithID:self.blog.objectID];
    
    if (contextPost && self.postID && [contextPost.postID isEqual:self.postID]) {
        return;
    }
	
	if(self.postID) {
        NSSet *posts = [contextBlog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@", self.postID]];
        self.post = [posts anyObject];
	}
}

- (void)save {
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext save:nil];
    }];
}

@end

@implementation Comment (WordPressApi)

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

#pragma mark - WPContentViewProvider protocol

- (NSString *)blogNameForDisplay {
    return self.author_url;
}

- (NSString *)statusForDisplay {
    NSString *status = [[self class] titleForStatus:self.status];
    if ([status isEqualToString:NSLocalizedString(@"Comments", @"")]) {
        status = nil;
    }
    return status;
}


@end
