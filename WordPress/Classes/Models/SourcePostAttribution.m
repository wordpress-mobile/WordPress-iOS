#import "SourcePostAttribution.h"
#import "ReaderPost.h"

NSString * const SourcePostAttributionTypePost = @"post";
NSString * const SourcePostAttributionTypeSite = @"site";

@implementation SourcePostAttribution

@dynamic permalink;
@dynamic authorName;
@dynamic authorURL;
@dynamic blogName;
@dynamic blogURL;
@dynamic blogID;
@dynamic postID;
@dynamic commentCount;
@dynamic likeCount;
@dynamic avatarURL;
@dynamic post;
@dynamic attributionType;

@end
