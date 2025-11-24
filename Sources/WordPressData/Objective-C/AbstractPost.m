#import "AbstractPost.h"
#import "Media.h"
#import "WordPressData-Swift.h"
#import "BasePost.h"

@import WordPressKit;
@import WordPressShared;

@implementation AbstractPost

@dynamic blog;
@dynamic dateModified;
@dynamic media;
@dynamic comments;
@dynamic featuredImage;
@dynamic revisions;
@dynamic confirmedChangesTimestamp;
@dynamic autoUploadAttemptsCount;
@dynamic autosaveContent;
@dynamic autosaveExcerpt;
@dynamic autosaveTitle;
@dynamic autosaveModifiedDate;
@dynamic autosaveIdentifier;
@dynamic foreignID;
@dynamic order;
@dynamic rawMetadata;
@dynamic rawOtherTerms;
@dynamic permalinkTemplateURL;
@synthesize voiceContent;

#pragma mark -
#pragma mark Revision management

- (AbstractPost *)revision
{
    [self willAccessValueForKey:@"revision"];
    AbstractPost *revision = [self primitiveValueForKey:@"revision"];
    [self didAccessValueForKey:@"revision"];

    return revision;
}

- (AbstractPost *)original
{
    [self willAccessValueForKey:@"original"];
    AbstractPost *original = [self primitiveValueForKey:@"original"];
    [self didAccessValueForKey:@"original"];

    return original;
}

#pragma mark - Helpers

- (BOOL)hasCategories
{
    return NO;
}

- (BOOL)hasTags
{
    return NO;
}

@end
