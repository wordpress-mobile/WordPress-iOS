#import "ReaderPost.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "SourcePostAttribution.h"
#import "WPAccount.h"
#import "WPAvatarSource.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressShared/NSString+XMLExtensions.h>
#import "WordPress-Swift.h"

// These keys are used in the getStoredComment method
NSString * const ReaderPostStoredCommentIDKey = @"commentID";
NSString * const ReaderPostStoredCommentTextKey = @"comment";

static NSString * const SourceAttributionSiteTaxonomy = @"site-pick";
static NSString * const SourceAttributionImageTaxonomy = @"image-pick";
static NSString * const SourceAttributionQuoteTaxonomy = @"quote-pick";
static NSString * const SourceAttributionStandardTaxonomy = @"standard-pick";

@implementation ReaderPost

@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic siteIconURL;
@dynamic blogName;
@dynamic blogDescription;
@dynamic blogURL;
@dynamic commentCount;
@dynamic commentsOpen;
@dynamic featuredImage;
@dynamic feedID;
@dynamic feedItemID;
@dynamic isBlogAtomic;
@dynamic isBlogPrivate;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic isWPCom;
@dynamic organizationID;
@dynamic likeCount;
@dynamic score;
@dynamic siteID;
@dynamic sortRank;
@dynamic sortDate;
@dynamic summary;
@dynamic comments;
@dynamic tags;
@dynamic topic;
@dynamic card;
@dynamic globalID;
@dynamic isLikesEnabled;
@dynamic isSharingEnabled;
@dynamic isSiteBlocked;
@dynamic sourceAttribution;
@dynamic isSavedForLater;
@dynamic isSeen;
@dynamic isSeenSupported;
@dynamic isSubscribedComments;
@dynamic canSubscribeComments;
@dynamic receivesCommentNotifications;

@dynamic primaryTag;
@dynamic primaryTagSlug;
@dynamic isExternal;
@dynamic isJetpack;
@dynamic wordCount;
@dynamic readingTime;
@dynamic crossPostMeta;
@dynamic railcar;
@dynamic inUse;

@synthesize rendered;

+ (instancetype)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost
                                     forTopic:(ReaderAbstractTopic *)topic
                                      context:(NSManagedObjectContext *) managedObjectContext
{
    NSError *error;
    ReaderPost *post;
    NSString *globalID = remotePost.globalID;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ReaderPost"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"globalID = %@ AND (topic = %@ OR topic = NULL)", globalID, topic];
    NSArray *arr = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

    BOOL existing = false;
    if (error) {
        DDLogError(@"Error fetching an existing reader post. - %@", error);
    } else if ([arr count] > 0) {
        post = (ReaderPost *)[arr objectAtIndex:0];
        existing = YES;
    } else {
        post = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                             inManagedObjectContext:managedObjectContext];
    }

    post.authorID = remotePost.authorID;
    post.author = remotePost.author;
    post.authorAvatarURL = remotePost.authorAvatarURL;
    post.authorDisplayName = remotePost.authorDisplayName;
    post.authorEmail = remotePost.authorEmail;
    post.authorURL = remotePost.authorURL;
    post.organizationID = remotePost.organizationID;
    post.siteIconURL = remotePost.siteIconURL;
    post.blogName = remotePost.blogName;
    post.blogDescription = remotePost.blogDescription;
    post.blogURL = remotePost.blogURL;
    post.commentCount = remotePost.commentCount;
    post.commentsOpen = remotePost.commentsOpen;
    post.date_created_gmt = [DateUtils dateFromISOString:remotePost.date_created_gmt];
    post.featuredImage = remotePost.featuredImage;
    post.feedID = remotePost.feedID;
    post.feedItemID = remotePost.feedItemID;
    post.globalID = remotePost.globalID;
    post.isBlogAtomic = remotePost.isBlogAtomic;
    post.isBlogPrivate = remotePost.isBlogPrivate;
    post.isFollowing = remotePost.isFollowing;
    post.isLiked = remotePost.isLiked;
    post.isReblogged = remotePost.isReblogged;
    post.isWPCom = remotePost.isWPCom;
    post.organizationID = remotePost.organizationID;
    post.likeCount = remotePost.likeCount;
    post.permaLink = remotePost.permalink;
    post.postID = remotePost.postID;
    post.postTitle = remotePost.postTitle;
    post.railcar = remotePost.railcar;
    post.score = remotePost.score;
    post.siteID = remotePost.siteID;
    post.sortDate = remotePost.sortDate;
    post.isSeen = remotePost.isSeen;
    post.isSeenSupported = remotePost.isSeenSupported;
    post.isSubscribedComments = remotePost.isSubscribedComments;
    post.canSubscribeComments = remotePost.canSubscribeComments;
    post.receivesCommentNotifications = remotePost.receivesCommentNotifications;

    if (existing && [topic isKindOfClass:[ReaderSearchTopic class]]) {
        // Failsafe.  The `read/search` endpoint might return the same post on
        // more than one page. If this happens preserve the *original* sortRank
        // to avoid content jumping around in the UI.
    } else {
        post.sortRank = remotePost.sortRank;
    }

    post.status = remotePost.status;
    post.summary = remotePost.summary;
    post.tags = remotePost.tags;
    post.isSharingEnabled = remotePost.isSharingEnabled;
    post.isLikesEnabled = remotePost.isLikesEnabled;
    post.isSiteBlocked = NO;

    if (remotePost.crossPostMeta) {
        if (!post.crossPostMeta) {
            ReaderCrossPostMeta *meta = (ReaderCrossPostMeta *)[NSEntityDescription insertNewObjectForEntityForName:[ReaderCrossPostMeta classNameWithoutNamespaces]
                                                                                     inManagedObjectContext:managedObjectContext];
            post.crossPostMeta = meta;
        }
        post.crossPostMeta.siteURL = remotePost.crossPostMeta.siteURL;
        post.crossPostMeta.postURL = remotePost.crossPostMeta.postURL;
        post.crossPostMeta.commentURL = remotePost.crossPostMeta.commentURL;
        post.crossPostMeta.siteID = remotePost.crossPostMeta.siteID;
        post.crossPostMeta.postID = remotePost.crossPostMeta.postID;
    } else {
        post.crossPostMeta = nil;
    }

    NSString *tag = remotePost.primaryTag;
    NSString *slug = remotePost.primaryTagSlug;
    if ([topic isKindOfClass:[ReaderTagTopic class]]) {
        ReaderTagTopic *tagTopic = (ReaderTagTopic *)topic;
        if ([tagTopic.slug isEqualToString:remotePost.primaryTagSlug]) {
            tag = remotePost.secondaryTag;
            slug = remotePost.secondaryTagSlug;
        }
    }
    post.primaryTag = tag;
    post.primaryTagSlug = slug;

    post.isExternal = remotePost.isExternal;
    post.isJetpack = remotePost.isJetpack;
    post.wordCount = remotePost.wordCount;
    post.readingTime = remotePost.readingTime;

    if (remotePost.sourceAttribution) {
        post.sourceAttribution = [self createOrReplaceFromRemoteDiscoverAttribution:remotePost.sourceAttribution forPost:post context:managedObjectContext];
    } else {
        post.sourceAttribution = nil;
    }

    post.content = [RichContentFormatter removeInlineStyles:[RichContentFormatter removeForbiddenTags:remotePost.content]];

    // assign the topic last.
    post.topic = topic;

    return post;
}

+ (SourcePostAttribution *)createOrReplaceFromRemoteDiscoverAttribution:(RemoteSourcePostAttribution *)remoteAttribution
                                                                forPost:(ReaderPost *)post
                                                                context:(NSManagedObjectContext *) managedObjectContext
{
    SourcePostAttribution *attribution = post.sourceAttribution;

    if (!attribution) {
        attribution = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SourcePostAttribution class])
                                             inManagedObjectContext:managedObjectContext];
    }
    attribution.authorName = remoteAttribution.authorName;
    attribution.authorURL = remoteAttribution.authorURL;
    attribution.avatarURL = remoteAttribution.avatarURL;
    attribution.blogName = remoteAttribution.blogName;
    attribution.blogURL = remoteAttribution.blogURL;
    attribution.permalink = remoteAttribution.permalink;
    attribution.blogID = remoteAttribution.blogID;
    attribution.postID = remoteAttribution.postID;
    attribution.commentCount = remoteAttribution.commentCount;
    attribution.likeCount = remoteAttribution.likeCount;
    attribution.attributionType = [self attributionTypeFromTaxonomies:remoteAttribution.taxonomies];
    return attribution;
}

+ (NSString *)attributionTypeFromTaxonomies:(NSArray *)taxonomies
{
    if ([taxonomies containsObject:SourceAttributionSiteTaxonomy]) {
        return SourcePostAttributionTypeSite;
    }

    if ([taxonomies containsObject:SourceAttributionImageTaxonomy] ||
        [taxonomies containsObject:SourceAttributionQuoteTaxonomy] ||
        [taxonomies containsObject:SourceAttributionStandardTaxonomy] ) {
        return SourcePostAttributionTypePost;
    }

    return nil;
}

- (BOOL)isCrossPost
{
    return self.crossPostMeta != nil;
}

- (BOOL)isAtomic
{
    return self.isBlogAtomic;
}

- (BOOL)isPrivate
{
    return self.isBlogPrivate;
}

- (BOOL)isP2Type
{
    NSInteger orgID = [self.organizationID intValue];
    return orgID == SiteOrganizationTypeP2 || orgID == SiteOrganizationTypeAutomattic;
}

- (NSString *)authorString
{
    if ([self.authorDisplayName length] > 0) {
        return self.authorDisplayName;
    }

    return self.author;
}

- (NSString *)avatar
{
    return self.authorAvatarURL;
}

- (UIImage *)cachedAvatarWithSize:(CGSize)size
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    if (!hash) {
        return nil;
    }
    return [[WPAvatarSource sharedSource] cachedImageForAvatarHash:hash ofType:type withSize:size];
}

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];

    if (hash) {
        [[WPAvatarSource sharedSource] fetchImageForAvatarHash:hash ofType:type withSize:size success:success];
    } else if (success) {
        success(nil);
    }
}

- (WPAvatarSourceType)avatarSourceTypeWithHash:(NSString **)hash
{
    if (self.authorAvatarURL) {
        NSURL *avatarURL = [NSURL URLWithString:self.authorAvatarURL];
        if (avatarURL) {
            return [[WPAvatarSource sharedSource] parseURL:avatarURL forAvatarHash:hash];
        }
    }
    if (self.blogURL) {
        *hash = [[[NSURL URLWithString:self.blogURL] host] md5];
        return WPAvatarSourceTypeBlavatar;
    }
    return WPAvatarSourceTypeUnknown;
}

- (NSURL *)featuredImageURL
{
    if ([self.featuredImage length]) {
        return [NSURL URLWithString:self.featuredImage];
    }
    return nil;
}

- (BOOL)contentIncludesFeaturedImage
{
    NSURL *featuredImageURL = [self featuredImageURL];
    NSString *featuredImage = [featuredImageURL absoluteString];
    if (!featuredImage) {
        return NO;
    }

    // Remove any query string params if needed (e.g. resize values)
    NSUInteger questionMarkLocation = [featuredImage rangeOfString:@"?" options:NSBackwardsSearch].location;
    if (questionMarkLocation != NSNotFound) {
        featuredImage = [featuredImage substringToIndex:questionMarkLocation];
    }

    // One URL might be http and the other https, so don't include the protocol in the check.
    NSString *scheme = [featuredImageURL scheme];
    if ([scheme length]) {
        NSInteger index = [scheme length] + 3; // protocol + ://
        featuredImage = [featuredImage substringFromIndex:index];
    }

    NSString *content = [self contentForDisplay];
    return ([content rangeOfString:featuredImage].location != NSNotFound);
}

#pragma mark - PostContentProvider protocol

- (NSString *)blogNameForDisplay
{
    if (self.blogName.length > 0) {
        return self.blogName;
    }
    return [[NSURL URLWithString:self.blogURL] host];
}

- (NSURL *)siteIconForDisplayOfSize:(NSInteger)size
{
    NSString *str;
    if ([self.siteIconURL length] > 0) {
        if ([self.siteIconURL rangeOfString:@"/blavatar/"].location == NSNotFound) {
            str = self.siteIconURL;
        } else {
            str = [NSString stringWithFormat:@"%@?s=%d&d=404", self.siteIconURL, size];
        }
        return [NSURL URLWithString:str];
    }
    return nil;
}

- (NSString *)titleForDisplay
{
    NSString *title = [[self.postTitle trim] stringByDecodingXMLCharacters];
    if (!title) {
        title = @"";
    }
    return title;
}

- (NSArray <NSString *> *)tagsForDisplay
{
    if (self.tags.length <= 0) {
        return @[];
    }

    NSArray *tags = [self.tags componentsSeparatedByString:@", "];

    return [tags sortedArrayUsingSelector:@selector(localizedCompare:)];
}

- (NSString *)authorForDisplay
{
    return [self authorString];
}

- (NSDate *)dateForDisplay
{
    return [self dateCreated];
}

- (NSString *)contentPreviewForDisplay
{
    return self.summary;
}

- (NSURL *)featuredImageURLForDisplay
{
    return [self featuredImageURL];
}

- (NSString *)likeCountForDisplay
{
    NSString *likeStr = NSLocalizedString(@"Like", @"Text for the 'like' button. Tapping marks a post in the reader as 'liked'.");
    NSString *likesStr = NSLocalizedString(@"Likes", @"Text for the 'like' button. Tapping removes the 'liked' status from a post.");

    NSInteger count = [self.likeCount integerValue];
    NSString *title;
    if (count == 0) {
        title = likeStr;
    } else if (count == 1) {
        title = [NSString stringWithFormat:@"%d %@", count, likeStr];
    } else {
        title = [NSString stringWithFormat:@"%d %@", count, likesStr];
    }

    return title;
}

- (SourceAttributionStyle)sourceAttributionStyle
{
    if ([self.sourceAttribution.attributionType isEqualToString:SourcePostAttributionTypePost]) {
        return SourceAttributionStylePost;
    } else if ([self.sourceAttribution.attributionType isEqualToString:SourcePostAttributionTypeSite]) {
        return SourceAttributionStyleSite;
    } else {
        return SourceAttributionStyleNone;
    }
}

- (NSString *)sourceAuthorNameForDisplay
{
    return self.sourceAttribution.authorName;
}

- (NSURL *)sourceAuthorURLForDisplay
{
    if (!self.sourceAttribution) {
        return nil;
    }
    return [NSURL URLWithString:self.sourceAttribution.authorURL];
}

- (NSURL *)sourceAvatarURLForDisplay
{
    if (!self.sourceAttribution) {
        return nil;
    }
    return [NSURL URLWithString:self.sourceAttribution.avatarURL];
}

- (NSString *)sourceBlogNameForDisplay
{
    return self.sourceAttribution.blogName;
}

- (NSURL *)sourceBlogURLForDisplay
{
    if (!self.sourceAttribution) {
        return nil;
    }
    return [NSURL URLWithString:self.sourceAttribution.blogURL];
}

- (BOOL)isSourceAttributionWPCom
{
    return (self.sourceAttribution.blogID) ? YES : NO;
}

- (NSURL *)avatarURLForDisplay
{
    return [NSURL URLWithString:self.authorAvatarURL];
}

- (NSString *)siteURLForDisplay
{
    return self.blogURL;
}

- (NSString *)siteHostNameForDisplay
{
    return self.blogURL.hostname;
}

- (NSString *)crossPostOriginSiteURLForDisplay
{
    return self.crossPostMeta.siteURL;
}

- (BOOL)isCommentCrossPost
{
    return self.crossPostMeta.commentURL.length > 0;
}

- (NSDictionary *)railcarDictionary
{
    if (!self.railcar) {
        return nil;
    }

    NSData *jsonData = [self.railcar dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)jsonObj;
    }
    return nil;
}

- (void) didSave {
    [super didSave];

    // A ReaderCard can have either a post, or a list of topics, but not both.
    // Since this card has a post, we can confidently set `topics` to NULL.
    if ([self respondsToSelector:@selector(card)] && self.card.count > 0) {
        self.card.allObjects[0].topics = NULL;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }
}

@end
