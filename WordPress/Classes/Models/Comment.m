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
@dynamic rawContent;
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

@end
