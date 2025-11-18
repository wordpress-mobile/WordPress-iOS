#import "BasePost.h"
#import "Media.h"

@import WordPressShared;

@implementation BasePost

@dynamic authorID;
@dynamic author;
@dynamic authorAvatarURL;
@dynamic content;
@dynamic date_created_gmt;
@dynamic postID;
@dynamic postTitle;
@dynamic password;
@dynamic remoteStatusNumber;
@dynamic permaLink;
@dynamic mt_excerpt;
@dynamic wp_slug;
@dynamic suggested_slug;
@dynamic pathForDisplayImage;

- (NSDate *)dateCreated
{
    return self.date_created_gmt;
}

- (void)setDateCreated:(NSDate *)localDate
{
    self.date_created_gmt = localDate;
}

- (BOOL)hasContent
{
    BOOL titleIsEmpty = self.postTitle ? self.postTitle.isEmpty : YES;
    BOOL contentIsEmpty = [self isContentEmpty];

    return !titleIsEmpty || !contentIsEmpty;
}

- (BOOL)isContentEmpty
{
    BOOL isContentAnEmptyGBParagraph = [self.content isEqualToString:@"<!-- wp:paragraph -->\n<p></p>\n<!-- /wp:paragraph -->"];
    return  self.content ? (self.content.isEmpty || isContentAnEmptyGBParagraph) : YES;
}

@end
