//
//  Comment.m
//  WordPress
//
//  Created by Chris Boyd on 6/17/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Comment.h"
#import "WPDataController.h"

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

+ (Comment *)newCommentForBlog:(Blog *)blog {
    Comment *comment = [[Comment alloc] initWithEntity:[NSEntityDescription entityForName:@"Comment"
                                                                      inManagedObjectContext:[blog managedObjectContext]]
                           insertIntoManagedObjectContext:[blog managedObjectContext]];
    
    comment.blog = blog;
    
    return comment;
}

+ (Comment *)findWithBlog:(Blog *)blog andCommentID:(NSNumber *)commentID {
    NSSet *results = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID == %@",commentID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;    
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

+ (Comment *)createOrReplaceFromDictionary:(NSDictionary *)commentInfo forBlog:(Blog *)blog {
    if ([commentInfo objectForKey:@"comment_id"] == nil) {
        return nil;
    }
    
    Comment *comment = [self findWithBlog:blog andCommentID:[[commentInfo objectForKey:@"comment_id"] numericValue]];
    
    if (comment == nil) {
        comment = [[Comment newCommentForBlog:blog] autorelease];
    }
    
    [comment updateFromDictionary:commentInfo];
    [comment findPost];
    
    return comment;
}

+ (NSString *)titleForStatus:(NSString *)status {
    if ([status isEqualToString:@"hold"]) {
        return @"Pending moderation";
    } else if ([status isEqualToString:@"approve"]) {
        return @"Comments";
    } else {
        return status;
    }

}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void)findPost {
    if (self.post && [self.post.postID isEqual:self.postID]) {
        return;
    }
    NSSet *posts = [self.blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@", self.postID]];
    
    if (posts && [posts count] > 0) {
        self.post = [posts anyObject];
    }
}

- (Comment *)newReply {
    Comment *reply = [Comment newCommentForBlog:self.blog];
    reply.postID = self.postID;
    reply.post = self.post;
    reply.parentID = self.commentID;
    reply.status = @"approve";

    return reply;
}

- (NSString *)postTitle {
    if (self.post) {
        return self.post.postTitle;
    } else {
        [self willAccessValueForKey:@"postTitle"];
        NSString *title = [self primitiveValueForKey:@"postTitle"];
        [self didAccessValueForKey:@"postTitle"];
        return title;
    }

}

- (BOOL)upload {
    if (self.commentID) {
        if([[WPDataController sharedInstance] wpEditComment:self]) {
			//OK
		    [self save];
			return YES;
		} 
    } else {
        NSNumber *commentID = [[WPDataController sharedInstance] wpNewComment:self];
        if (commentID) {
			self.commentID = commentID;
			[self save];
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Moderation
- (BOOL)approve {
	NSString *prevStatus = self.status;
    if (![self.status isEqualToString:@"approve"]) {
        self.status = @"approve";
    }
    if(![self upload]) {
		self.status = prevStatus;
		return NO;
	}
	return YES;
}

- (BOOL)unapprove {
	NSString *prevStatus = self.status;
    if (![self.status isEqualToString:@"hold"]) {
        self.status = @"hold";
    }
    if(![self upload]) {
		self.status = prevStatus;
		return NO;
	}
	
	return YES;	
}

- (BOOL)spam {
	NSString *prevStatus = self.status;
    if (![self.status isEqualToString:@"spam"]) {
        self.status = @"spam";
    }
	if(![self upload]) {
		self.status = prevStatus;
		return NO;
	} else {
		[[self managedObjectContext] deleteObject:self];
	}
	
	return YES;	
}

- (BOOL)remove {
    if ([[WPDataController sharedInstance] wpDeleteComment:self]) {
        [[self managedObjectContext] deleteObject:self];
    } else 
		return NO;
	
	return YES;
}

@end
