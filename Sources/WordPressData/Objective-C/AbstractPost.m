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

- (AbstractPost *)cloneFrom:(AbstractPost *)source
{
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        if (![key isEqualToString:@"permalink"]) {
            [self setValue:[source valueForKey:key] forKey:key];
        }
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            continue;
        } else if ([key isEqualToString:@"comments"]) {
            [self setComments:[source comments]];
        } else {
            [self setValue: [source valueForKey:key] forKey: key];
        }
    }

    return self;
}

- (AbstractPost *)createRevision
{
    NSParameterAssert(self.revision == nil);

    AbstractPost *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class) inManagedObjectContext:self.managedObjectContext];
    [post cloneFrom:self];
    post.remoteStatus = AbstractPostRemoteStatusLocalRevision;
    [post setValue:self forKey:@"original"];
    [post setValue:nil forKey:@"revision"];
    return post;
}

- (void)deleteRevision
{
    if (self.revision) {
        [self.managedObjectContext performBlockAndWait :^{
            [self.managedObjectContext deleteObject:self.revision];
            [self willChangeValueForKey:@"revision"];
            [self setPrimitiveValue:nil forKey:@"revision"];
            [self didChangeValueForKey:@"revision"];
        }];
    }
}

- (void)applyRevision
{
    if ([self isOriginal]) {
        [self cloneFrom:self.revision];
    }
}

- (AbstractPost *)updatePostFrom:(AbstractPost *)revision
{
    for (NSString *key in [[[revision entity] attributesByName] allKeys]) {
        if ([key isEqualToString:@"postTitle"] ||
            [key isEqualToString:@"content"]) {
            [self setValue:[revision valueForKey:key] forKey:key];
        } else if ([key isEqualToString:@"dateModified"]) {
            [self setValue:[NSDate date] forKey:key];
        }
    }
    return self;
}

- (BOOL)isRevision
{
    return (![self isOriginal]);
}

- (BOOL)isOriginal
{
    return ([self original] == nil);
}

- (AbstractPost *)latest
{
    return [self hasRevision] ? [[self revision] latest] : self;
}

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

- (BOOL)dateCreatedIsNilOrEqualToDateModified
{
    return self.date_created_gmt == nil || [self.date_created_gmt isEqualToDate:self.dateModified];
}

- (BOOL)hasPhoto
{
    if ([self.media count] == 0) {
        return NO;
    }

    if (self.featuredImage != nil) {
        return YES;
    }

    for (Media *media in self.media) {
        if (media.mediaType == MediaTypeImage) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)hasVideo
{
    if ([self.media count] == 0) {
        return NO;
    }

    for (Media *media in self.media) {
        if (media.mediaType ==  MediaTypeVideo) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)hasCategories
{
    return NO;
}

- (BOOL)hasTags
{
    return NO;
}

- (BOOL)hasRevision
{
    return self.revision != nil;
}

- (BOOL)hasRemote
{
    return ((self.postID != nil) && ([self.postID longLongValue] > 0));
}

#pragma mark - Convenience methods

// If the post has a scheduled status.
- (BOOL)isScheduled
{
    return ([self.status isEqualToString:PostStatusScheduled]);
}

- (BOOL)isDraft
{
    return [self.status isEqualToString:PostStatusDraft];
}

- (BOOL)isPublished
{
    return [self.status isEqualToString:PostStatusPublish];
}

- (BOOL)originalIsDraft
{
    if ([self.status isEqualToString:PostStatusDraft]) {
        return YES;
    } else if (self.isRevision && [self.original.status isEqualToString:PostStatusDraft]) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldPublishImmediately
{
    /// - warning: Yes, this is WordPress logic and it matches the behavior on
    /// the web. If `dateCreated` is the same as `dateModified`, the system
    /// uses it to represent a "no publish date selected" scenario.
    return [self originalIsDraft] && [self dateCreatedIsNilOrEqualToDateModified];
}

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
