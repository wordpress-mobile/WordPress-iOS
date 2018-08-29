#import "AbstractPost.h"
#import "Media.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
#import "BasePost.h"
@import WordPressKit;

@implementation AbstractPost

@dynamic blog;
@dynamic dateModified;
@dynamic media;
@dynamic metaIsLocal;
@dynamic metaPublishImmediately;
@dynamic comments;
@dynamic featuredImage;
@dynamic isStickyPost;

@synthesize restorableStatus;

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus
{
    switch ([remoteStatus intValue]) {
        case AbstractPostRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
        case AbstractPostRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
        case AbstractPostRemoteStatusSync:
            return NSLocalizedString(@"Posts", @"");
        default:
            return NSLocalizedString(@"Local", @"");
    }
}

+ (NSString *)titleForStatus:(NSString *)status
{
    if ([status isEqualToString:PostStatusDraft]) {
        return NSLocalizedString(@"Draft", @"Name for the status of a draft post.");

    } else if ([status isEqualToString:PostStatusPending]) {
        return NSLocalizedString(@"Pending review", @"Name for the status of a post pending review.");

    } else if ([status isEqualToString:PostStatusPrivate]) {
        return NSLocalizedString(@"Privately published", @"Name for the status of a post that is marked private.");

    } else if ([status isEqualToString:PostStatusPublish]) {
        return NSLocalizedString(@"Published", @"Name for the status of a published post.");

    } else if ([status isEqualToString:PostStatusTrash]) {
        return NSLocalizedString(@"Trashed", @"Name for the status of a trashed post");

    } else if ([status isEqualToString:PostStatusScheduled]) {
        return NSLocalizedString(@"Scheduled", @"Name for the status of a scheduled post");
    }
    
    return status;
}

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

+ (NSString *const)remoteUniqueIdentifier
{
    return @"";
}

#pragma mark - Life Cycle Methods

- (void)awakeFromFetch
{
    [super awakeFromFetch];

    if (!self.isDeleted && self.remoteStatus == AbstractPostRemoteStatusPushing) {
        // If we've just been fetched and our status is AbstractPostRemoteStatusPushing then something
        // when wrong saving -- the app crashed for instance. So change our remote status to failed.
        [self setPrimitiveValue:@(AbstractPostRemoteStatusFailed) forKey:@"remoteStatusNumber"];
    }
}

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

- (NSString *)statusTitle
{
    return [AbstractPost titleForStatus:self.status];
}

- (AbstractPostRemoteStatus)remoteStatus
{
    return (AbstractPostRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(AbstractPostRemoteStatus)aStatus
{
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (NSString *)remoteStatusText
{
    return [AbstractPost titleForRemoteStatus:self.remoteStatusNumber];
}

#pragma mark -
#pragma mark Revision management

- (void)cloneFrom:(AbstractPost *)source
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
    return [self isDraft] && [self dateCreatedIsNilOrEqualToDateModified];
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
    if ([self isDraft] || [self.status isEqualToString:PostStatusPending]) {
        NSString *shortDate = [[self dateModified] mediumString];
        NSString *lastModified = NSLocalizedString(@"last-modified",@"A label for a post's last-modified date.");
        return [NSString stringWithFormat:@"%@ (%@)", shortDate, lastModified];
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
    if(self.remoteStatus == AbstractPostRemoteStatusLocal || self.remoteStatus == AbstractPostRemoteStatusFailed) {
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

- (void)markRemoteStatusFailed
{
    self.remoteStatus = AbstractPostRemoteStatusFailed;
    [self save];
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
