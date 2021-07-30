#import "Comment.h"
#import "ContextManager.h"
#import "Blog.h"
#import "BasePost.h"
#import "WordPress-Swift.h"


@implementation Comment

@dynamic blog;
@dynamic post;
@dynamic author;
@dynamic author_email;
@dynamic author_ip;
@dynamic author_url;
@dynamic authorAvatarURL;
@dynamic commentID;
@dynamic content;
@dynamic dateCreated;
@dynamic depth;
@dynamic hierarchy;
@dynamic link;
@dynamic parentID;
@dynamic postID;
@dynamic postTitle;
@dynamic status;
@dynamic type;
@dynamic isLiked;
@dynamic likeCount;
@dynamic canModerate;
@synthesize isNew;
@synthesize attributedContent;

/// This is a temporary workaround for issue #16950, unblocking 17.9 release.
/// Previously, this method was migrated to Swift – but due to the crashing issue after replying to a comment that triggers creation
/// of a new section, moving this back to the Objective-C land somehow _magically_ fixed the problem. *cue the rainbows*.
///
/// Let's move this back to Swift once we figure out how to properly fix this.
///
- (NSString *)sectionIdentifier
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    return [formatter stringFromDate:self.dateCreated];
}

@end
