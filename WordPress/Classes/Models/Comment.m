#import "Comment.h"
#import "ContextManager.h"
#import "Blog.h"
#import "BasePost.h"
#import "NSString+XMLExtensions.h"
#import "NSString+HTML.h"
#import "NSString+Helpers.h"

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
@dynamic depth;
@dynamic authorAvatarURL;
@synthesize isNew;
@synthesize attributedContent;

#pragma mark - Helper methods

+ (NSString *)titleForStatus:(NSString *)status
{
    if ([status isEqualToString:@"hold"]) {
        return NSLocalizedString(@"Pending moderation", @"");
    } else if ([status isEqualToString:@"approve"]) {
        return NSLocalizedString(@"Comments", @"");
    }

    return status;
}

- (NSString *)postTitle
{
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

- (NSString *)author
{
    NSString *authorName = nil;

    [self willAccessValueForKey:@"author"];
    authorName = [self primitiveValueForKey:@"author"];
    [self didAccessValueForKey:@"author"];

    if (authorName == nil || [@"" isEqualToString:authorName]) {
        authorName = NSLocalizedString(@"Anonymous", @"the comment has an anonymous author.");
    }
    return authorName;

}

- (NSDate *)dateCreated
{
    NSDate *date = nil;

    [self willAccessValueForKey:@"dateCreated"];
    date = [self primitiveValueForKey:@"dateCreated"];
    [self didAccessValueForKey:@"dateCreated"];

    return date;
}


#pragma mark - WPContentViewProvider protocol

- (NSString *)titleForDisplay
{
    return [self.postTitle stringByDecodingXMLCharacters];
}

- (NSString *)authorForDisplay
{
    return [self.author length] > 0 ? [[self.author stringByDecodingXMLCharacters] trim] : [self.author_email trim];
}

- (NSString *)blogNameForDisplay
{
    return self.author_url;
}

- (NSString *)statusForDisplay
{
    NSString *status = [[self class] titleForStatus:self.status];
    if ([status isEqualToString:NSLocalizedString(@"Comments", @"")]) {
        status = nil;
    }
    return status;
}

//- (NSString *)blogNameForDisplay
//{
//    return nil;
//}
//
//- (NSString *)statusForDisplay
//{
//    return self.status;
//}

- (NSString *)contentForDisplay
{
    // Unescape HTML characters and add <br /> tags
    NSString *commentContent = [[self.content stringByDecodingXMLCharacters] trim];
    // Don't add <br /> tags after an HTML tag, as DTCoreText will handle that spacing for us
    NSRegularExpression *removeNewlinesAfterHtmlTags = [NSRegularExpression regularExpressionWithPattern:@"(?<=\\>)\n\n" options:0 error:nil];
    commentContent = [removeNewlinesAfterHtmlTags stringByReplacingMatchesInString:commentContent options:0 range:NSMakeRange(0, [commentContent length]) withTemplate:@""];
    commentContent = [commentContent stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"];

    return commentContent;
}

- (NSString *)contentPreviewForDisplay
{
    return [[[self.content stringByDecodingXMLCharacters] stringByStrippingHTML] stringByNormalizingWhitespace];
}

- (NSURL *)avatarURLForDisplay
{
    return [NSURL URLWithString:self.authorAvatarURL];
}

- (NSString *)gravatarEmailForDisplay
{
    return [self.author_email trim];
}

- (NSDate *)dateForDisplay
{
    return self.dateCreated;
}


@end
