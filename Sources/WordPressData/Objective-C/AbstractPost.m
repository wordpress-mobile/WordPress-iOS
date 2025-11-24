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

#pragma mark - Life Cycle Methods

- (void)save
{
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

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

- (BOOL)hasRemote
{
    return ((self.postID != nil) && ([self.postID longLongValue] > 0));
}

#pragma mark - Convenience methods

- (NSURL *)blogURL
{
    return [NSURL URLWithString:self.blog.url];
}

- (BOOL)isPrivateAtWPCom
{
    return self.blog.isPrivateAtWPCom;
}

#pragma mark - Post

- (void)updatePathForDisplayImageBasedOnContent
{
    // First lets check the post content for a suitable image
    NSString *result = [DisplayableImageHelper searchPostContentForImageToDisplay:self.content];
    if (result.length > 0) {
        self.pathForDisplayImage = result;
    }
    // If none found let's see if some galleries are available
    NSSet *mediaIDs = [DisplayableImageHelper searchPostContentForAttachmentIdsInGalleries:self.content];
    for (Media *media in self.blog.media) {
        NSNumber *mediaID = media.mediaID;
        if (mediaID && [mediaIDs containsObject:mediaID]) {
            result = media.remoteURL;
        }
    }
    self.pathForDisplayImage = result;    
}

- (void)setParsedOtherTerms:(NSDictionary<NSString *, NSArray<NSString *> *> *)data
{
    if (data == nil) {
        self.rawOtherTerms = nil;
    } else {
        self.rawOtherTerms = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    }
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)parseOtherTerms
{
    if (self.rawOtherTerms == nil) {
        return [NSDictionary dictionary];
    }

    return [NSJSONSerialization JSONObjectWithData:self.rawOtherTerms options:0 error:nil] ?: [NSDictionary dictionary];
}

@end
