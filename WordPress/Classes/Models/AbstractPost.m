#import "AbstractPost.h"
#import "Media.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
#import "BasePost.h"
@import WordPressKit;

@interface AbstractPost ()

/**
 The following pair of properties is used to confirm that the post we'll be trying to automatically retry uploading,
 hasn't changed since user has tapped on "confirm", and that we're not suddenly trying to auto-upload a post that the user
 might have already forgotten about.

 The public-facing counterparts of those is the `shouldAttemptAutoUpload` property.
 */

@property (nonatomic, strong, nullable) NSString *confirmedChangesHash;
@property (nonatomic, strong, nullable) NSDate *confirmedChangesTimestamp;

@end

@implementation AbstractPost

@dynamic blog;
@dynamic dateModified;
@dynamic media;
@dynamic metaIsLocal;
@dynamic metaPublishImmediately;
@dynamic comments;
@dynamic featuredImage;
@dynamic revisions;
@dynamic confirmedChangesHash;
@dynamic confirmedChangesTimestamp;
@dynamic autoUploadAttemptsCount;
@dynamic autosaveContent;
@dynamic autosaveExcerpt;
@dynamic autosaveTitle;
@dynamic autosaveModifiedDate;

@synthesize restorableStatus;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"metaIsLocal"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"remoteStatusNumber"]];

    } else if ([key isEqualToString:@"metaPublishImmediately"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"date_created_gmt"]];
    }

    return keyPaths;
}

#pragma mark - Life Cycle Methods

- (void)remove
{
    if (self.remoteStatus == AbstractPostRemoteStatusPushing || self.remoteStatus == AbstractPostRemoteStatusLocal) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadCancelled" object:self];
    }

    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
    }];

}

- (void)save
{
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}


#pragma mark - Getters/Setters

- (void)setRemoteStatusNumber:(NSNumber *)remoteStatusNumber
{
    NSString *key = @"remoteStatusNumber";
    [self willChangeValueForKey:key];
    self.metaIsLocal = ([remoteStatusNumber integerValue] == AbstractPostRemoteStatusLocal);
    [self setPrimitiveValue:remoteStatusNumber forKey:key];
    [self didChangeValueForKey:key];
}

- (void)setDate_created_gmt:(NSDate *)date_created_gmt
{
    NSString *key = @"date_created_gmt";
    [self willChangeValueForKey:key];
    self.metaPublishImmediately = [self shouldPublishImmediately];
    [self setPrimitiveValue:date_created_gmt forKey:key];
    [self didChangeValueForKey:key];
}

- (void)setDateCreated:(NSDate *)localDate
{
    self.date_created_gmt = localDate;

    /*
     If the date is nil it means publish immediately so set the status to publish.
     If the date is in the future set the status to scheduled if current status is published.
     If the date is now or in the past, and the status is scheduled, set the status
     to published.
     */
    if ([self dateCreatedIsNilOrEqualToDateModified]) {
        // A nil date means publish immediately.
        self.status = PostStatusPublish;

    } else if ([self hasFuturePublishDate]) {
        // Needs to be a nested conditional so future date + scheduled status
        // is handled correctly.
        if ([self.status isEqualToString:PostStatusPublish]) {
            self.status = PostStatusScheduled;
        }
    } else if ([self.status isEqualToString:PostStatusScheduled]) {
        self.status = PostStatusPublish;
    }
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
    if ([self isRevision]) {
        DDLogInfo(@"!!! Attempted to create a revision of a revision");
        return self;
    }
    if (self.revision) {
        DDLogInfo(@"!!! Already have revision");
        return self.revision;
    }

    AbstractPost *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class) inManagedObjectContext:self.managedObjectContext];
    [post cloneFrom:self];
    [post setValue:self forKey:@"original"];
    [post setValue:nil forKey:@"revision"];
    post.isFeaturedImageChanged = self.isFeaturedImageChanged;
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
        self.isFeaturedImageChanged = self.revision.isFeaturedImageChanged;
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
    self.isFeaturedImageChanged = revision.isFeaturedImageChanged;
    return self;
}

- (void)updateRevision
{
    if ([self isRevision]) {
        [self cloneFrom:self.original];
        self.isFeaturedImageChanged = self.original.isFeaturedImageChanged;
    }
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
    // Even though we currently only support 1 revision per-post, we have plans to support multiple
    // revisions in the future.  That's the reason why we call `[[self revision] latest]` below.
    //
    //  - Diego Rey Mendez, May 19, 2016
    //
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

- (NSString *)availableStatusForPublishOrScheduled
{
    if ([self hasFuturePublishDate]) {
        return PostStatusScheduled;
    }
    return PostStatusPublish;
}

- (NSArray *)availableStatusesForEditing
{
    // Note: Read method description before changing values.
    return @[PostStatusDraft,
             PostStatusPending,
             [self availableStatusForPublishOrScheduled]];
}

- (BOOL)hasSiteSpecificChanges
{
    if (![self isRevision]) {
        return NO;
    }

    AbstractPost *original = (AbstractPost *)self.original;

    //Do not move the Featured Image check below in the code.
    if ((self.featuredImage != original.featuredImage) && (![self.featuredImage isEqual:original.featuredImage])) {
        self.isFeaturedImageChanged = YES;
        return YES;
    }

    self.isFeaturedImageChanged = NO;

    // Relationships are not going to be nil, just empty sets,
    // so we can avoid the extra check
    if (![self.media isEqual:original.media]) {
        return YES;
    }

    return NO;
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

- (BOOL)isFailed
{
    return self.remoteStatus == AbstractPostRemoteStatusFailed || [[MediaCoordinator shared] hasFailedMediaFor:self] || self.hasFailedMedia;
}

- (BOOL)hasFailedMedia
{
    if ([self.media count] == 0) {
        return NO;
    }

    for (Media *media in self.media) {
        if (media.remoteStatus ==  MediaRemoteStatusFailed) {
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

- (BOOL)hasNeverAttemptedToUpload
{
    return self.remoteStatus == AbstractPostRemoteStatusLocal;
}

- (BOOL)hasRemote
{
    return ((self.postID != nil) && ([self.postID longLongValue] > 0));
}

- (void)findComments
{
    NSSet *comments = [self.blog.comments filteredSetUsingPredicate:
                       [NSPredicate predicateWithFormat:@"(postID == %@) AND (post == NULL)", self.postID]];
    if ([comments count] > 0) {
        [self addComments:comments];
    }
}



#pragma mark - Convenience methods

// This is different than isScheduled. See .h for details.
- (BOOL)hasFuturePublishDate
{
    if (!self.date_created_gmt) {
        return NO;
    }
    return (self.date_created_gmt == [self.date_created_gmt laterDate:[NSDate date]]);
}

// If the post has a scheduled status.
- (BOOL)isScheduled
{
    return ([self.status isEqualToString:PostStatusScheduled]);
}

- (BOOL)isDraft
{
    return [self.status isEqualToString:PostStatusDraft];
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

- (void)publishImmediately
{
    self.dateModified = [NSDate date];
    [self setDateCreated:self.dateModified];
}

- (BOOL)shouldPublishImmediately
{
    return [self originalIsDraft] && [self dateCreatedIsNilOrEqualToDateModified];
}

- (NSString *)authorNameForDisplay
{
    return [NSString makePlainText:self.author];
}

- (NSURL *)avatarURLForDisplay
{
    return [NSURL URLWithString:self.blog.icon];
}

- (NSString *)blogNameForDisplay
{
    return [NSString makePlainText:self.blog.settings.name];
}

- (NSURL *)blogURL
{
    return [NSURL URLWithString:self.blog.url];
}

- (NSString *)blogURLForDisplay
{
    return self.blog.displayURL;
}

- (NSString *)blavatarForDisplay
{
    return self.blog.icon;
}

- (NSString *)contentPreviewForDisplay
{
    return self.mt_excerpt;
}

- (NSString *)dateStringForDisplay
{
    if ([self originalIsDraft] || [self.status isEqualToString:PostStatusPending]) {
        return [[self dateModified] mediumString];
    } else if ([self isScheduled]) {
        return [[self dateCreated] mediumStringWithTime];
    } else if ([self shouldPublishImmediately]) {
        return NSLocalizedString(@"Publish Immediately",@"A short phrase indicating a post is due to be immedately published.");
    }
    return [[self dateCreated] mediumString];
}

- (BOOL)supportsStats
{
    return [self.blog supports:BlogFeatureStats] && [self hasRemote];
}

- (BOOL)isPrivate
{
    return self.blog.isPrivate;
}

- (BOOL)isMultiAuthorBlog
{
    return self.blog.isMultiAuthor;
}

- (BOOL)isUploading
{
    return self.remoteStatus == AbstractPostRemoteStatusPushing;
}


#pragma mark - Post

- (BOOL)canSave
{
    NSString* titleWithoutSpaces = [self.postTitle stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* contentWithoutSpaces = [self.content stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    BOOL isTitleEmpty = (titleWithoutSpaces == nil || titleWithoutSpaces.length == 0);
    BOOL isContentEmpty = (contentWithoutSpaces == nil || contentWithoutSpaces.length == 0);
    BOOL areBothTitleAndContentsEmpty = isTitleEmpty && isContentEmpty;
    
    return (!areBothTitleAndContentsEmpty && [self hasUnsavedChanges]);
}

- (BOOL)hasUnsavedChanges
{
    return [self hasLocalChanges] || [self hasRemoteChanges];
}

- (BOOL)hasLocalChanges
{
    if(self.remoteStatus == AbstractPostRemoteStatusLocal ||
       self.remoteStatus == AbstractPostRemoteStatusFailed ||
       self.remoteStatus == AbstractPostRemoteStatusAutoSaved) {
        return YES;
    }
    
    if (![self isRevision]) {
        return NO;
    }
    
    if ([self hasSiteSpecificChanges]) {
        return YES;
    }
    
    AbstractPost *original = (AbstractPost *)self.original;
    
    // We need the extra check since [nil isEqual:nil] returns NO
    // and because @"" != nil
    if (!([self.postTitle length] == 0 && [original.postTitle length] == 0)
        && (![self.postTitle isEqual:original.postTitle])) {
        return YES;
    }
    
    if (!([self.content length] == 0 && [original.content length] == 0)
        && (![self.content isEqual:original.content])) {
        return YES;
    }
    
    if (!([self.status length] == 0 && [original.status length] == 0)
        && (![self.status isEqual:original.status])) {
        return YES;
    }
    
    if (!([self.password length] == 0 && [original.password length] == 0)
        && (![self.password isEqual:original.password])) {
        return YES;
    }
    
    if ((self.dateCreated != original.dateCreated)
        && (![self.dateCreated isEqual:original.dateCreated])) {
        return YES;
    }
    
    if (!([self.permaLink length] == 0 && [original.permaLink length] == 0)
        && (![self.permaLink isEqual:original.permaLink])) {
        return YES;
    }
    
    if (!([self.mt_excerpt length] == 0 && [original.mt_excerpt length] == 0)
        && (![self.mt_excerpt isEqual:original.mt_excerpt]))
    {
        return YES;
    }

    if (!([self.wp_slug length] == 0 && [original.wp_slug length] == 0)
        && (![self.wp_slug isEqual:original.wp_slug]))
    {
        return YES;
    }

    return NO;
}

- (BOOL)hasRemoteChanges
{
    return (self.hasRemote == NO
            || self.remoteStatus == AbstractPostRemoteStatusFailed);
}

- (BOOL)shouldAttemptAutoUpload {
    if (!self.confirmedChangesTimestamp || !self.confirmedChangesHash) {
        return NO;
    }

    NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:self.confirmedChangesTimestamp];

    BOOL timeDifferenceWithinRange = timeDifference <= (60 * 60 * 24 * 2);
    // We want the user's confirmation to upload a thing to expire after 48h.
    // This probably should be calculated using NSCalendar APIs — but those
    // can get really expensive. This method can potentially be called a lot during
    // scrolling of a Post List — and for our specific use-case, being slightly innacurate here in terms of
    // leap seconds or other calendrical oddities doesn't actually matter.

    BOOL hashesEqual = [self.confirmedChangesHash isEqualToString:[self calculateConfirmedChangesContentHash]];

    return hashesEqual && timeDifferenceWithinRange;
}

- (void)setShouldAttemptAutoUpload:(BOOL)shouldAttemptAutoUpload {
    if (shouldAttemptAutoUpload) {
        NSString *currentHash = [self calculateConfirmedChangesContentHash];
        NSDate *now = [NSDate date];

        self.confirmedChangesHash = currentHash;
        self.confirmedChangesTimestamp = now;
    } else {
        self.confirmedChangesHash = @"";
        self.confirmedChangesTimestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    }
}

- (BOOL)wasAutoUploadCancelled {
    return [self.confirmedChangesHash isEqualToString:@""]
    && [self.confirmedChangesTimestamp isEqualToDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];
}

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

@end
