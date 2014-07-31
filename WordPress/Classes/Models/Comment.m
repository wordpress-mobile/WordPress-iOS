#import "Comment.h"
#import "ContextManager.h"

NSString * const CommentUploadFailedNotification = @"CommentUploadFailed";

NSString * const CommentStatusPending = @"hold";
NSString * const CommentStatusApproved = @"approve";
NSString * const CommentStatusDisapproved = @"trash";
NSString * const CommentStatusSpam = @"spam";

// draft is used for comments that have been composed but not succesfully uploaded yet
NSString * const CommentStatusDraft = @"draft";

@implementation Comment
@dynamic blog;
@dynamic post;
@synthesize isNew;

#pragma mark - Helper methods

+ (NSString *)titleForStatus:(NSString *)status {
    if ([status isEqualToString:@"hold"]) {
        return NSLocalizedString(@"Pending moderation", @"");
    } else if ([status isEqualToString:@"approve"]) {
        return NSLocalizedString(@"Comments", @"");
    }

    return status;
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
