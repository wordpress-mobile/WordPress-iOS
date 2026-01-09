#import "PostHelper.h"
#import "WordPressData-Swift.h"

@import WordPressKit;
@import WordPressKitModels;
@import WordPressShared;
@import NSObject_SafeExpectations;

PostServiceType const PostServiceTypePost = @"post";
PostServiceType const PostServiceTypePage = @"page";
PostServiceType const PostServiceTypeAny = @"any";

static NSString * const SourceAttributionSiteTaxonomy = @"site-pick";
static NSString * const SourceAttributionImageTaxonomy = @"image-pick";
static NSString * const SourceAttributionQuoteTaxonomy = @"quote-pick";
static NSString * const SourceAttributionStandardTaxonomy = @"standard-pick";

@implementation PostHelper

+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)managedObjectContext {
    [self updatePost:post withRemotePost:remotePost inContext:managedObjectContext overwrite:NO];
}

+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)managedObjectContext overwrite:(BOOL)overwrite {
    if ((post.revision != nil && !overwrite)) {
        return;
    }

    NSNumber *previousPostID = post.postID;
    post.postID = remotePost.postID;
    // Used to populate author information for self-hosted sites.
    BlogAuthor *author = [post.blog getAuthorWithId:remotePost.authorID];

    post.author = remotePost.authorDisplayName ?: author.displayName;
    post.authorID = remotePost.authorID;
    post.date_created_gmt = remotePost.date;
    post.dateModified = remotePost.dateModified;
    post.postTitle = remotePost.title;
    post.permaLink = [remotePost.URL absoluteString];
    post.content = remotePost.content;
    post.status = remotePost.status;
    post.password = remotePost.password;
    post.order = remotePost.order;

    if (remotePost.postThumbnailID != nil) {
        post.featuredImage = [Media existingOrStubMediaWithMediaID: remotePost.postThumbnailID inBlog:post.blog];
    } else {
        post.featuredImage = nil;
    }

    post.pathForDisplayImage = remotePost.pathForDisplayImage;
    if (post.pathForDisplayImage.length == 0) {
        [post updatePathForDisplayImageBasedOnContent];
    }
    post.authorAvatarURL = remotePost.authorAvatarURL ?: author.avatarURL;
    post.mt_excerpt = remotePost.excerpt;
    post.wp_slug = remotePost.slug;
    post.suggested_slug = remotePost.suggestedSlug;
    post.permalinkTemplateURL = remotePost.permalinkTemplateURL;

    if ([remotePost.revisions wp_isValidObject]) {
        post.revisions = [remotePost.revisions copy];
    }

    if (remotePost.postID != previousPostID) {
        [self updateCommentsForPost:post];
    }

    post.rawMetadata = [PostHelper makeRawMetadataFrom:remotePost];
    post.foreignID = [PostHelper getForeignIDFor:remotePost];
    [post setParsedOtherTerms:remotePost.otherTerms];

    post.autosaveTitle = remotePost.autosave.title;
    post.autosaveExcerpt = remotePost.autosave.excerpt;
    post.autosaveContent = remotePost.autosave.content;
    post.autosaveModifiedDate = remotePost.autosave.modifiedDate;
    post.autosaveIdentifier = remotePost.autosave.identifier;

    if ([post isKindOfClass:[Page class]]) {
        Page *pagePost = (Page *)post;
        pagePost.parentID = remotePost.parentID;
    } else if ([post isKindOfClass:[Post class]]) {
        Post *postPost = (Post *)post;
        postPost.commentsStatus = remotePost.commentsStatus;
        postPost.pingsStatus = remotePost.pingsStatus;
        postPost.commentCount = remotePost.commentCount;
        postPost.likeCount = remotePost.likeCount;
        postPost.postFormat = remotePost.format;
        postPost.tags = [remotePost.tags componentsJoinedByString:@","];
        postPost.postType = remotePost.type;
        postPost.isStickyPost = (remotePost.isStickyPost != nil) ? remotePost.isStickyPost.boolValue : NO;
        [self updatePost:postPost withRemoteCategories:remotePost.categories inContext:managedObjectContext];

        NSString *publicID = nil;
        NSString *publicizeMessage = nil;
        NSString *publicizeMessageID = nil;
        if (remotePost.metadata) {
            NSDictionary *latitudeDictionary = [self dictionaryWithKey:@"geo_latitude" inMetadata:remotePost.metadata];
            NSDictionary *longitudeDictionary = [self dictionaryWithKey:@"geo_longitude" inMetadata:remotePost.metadata];
            NSDictionary *geoPublicDictionary = [self dictionaryWithKey:@"geo_public" inMetadata:remotePost.metadata];
            if (latitudeDictionary && longitudeDictionary) {
                NSNumber *latitude = [latitudeDictionary numberForKey:@"value"];
                NSNumber *longitude = [longitudeDictionary numberForKey:@"value"];
                CLLocationCoordinate2D coord;
                coord.latitude = [latitude doubleValue];
                coord.longitude = [longitude doubleValue];
                publicID = [geoPublicDictionary stringForKey:@"id"];
            }
            NSDictionary *publicizeMessageDictionary = [self dictionaryWithKey:@"_wpas_mess" inMetadata:remotePost.metadata];
            publicizeMessage = [publicizeMessageDictionary stringForKey:@"value"];
            publicizeMessageID = [publicizeMessageDictionary stringForKey:@"id"];
        }
        postPost.publicID = publicID;
        postPost.publicizeMessage = publicizeMessage;
        postPost.publicizeMessageID = publicizeMessageID;
        postPost.disabledPublicizeConnections = [self disabledPublicizeConnectionsForPost:post andMetadata:remotePost.metadata];
    }
}

+ (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories inContext:(NSManagedObjectContext *)managedObjectContext {
    NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
    [categories removeAllObjects];
    for (RemotePostCategory *remoteCategory in remoteCategories) {
        PostCategory *category = [PostHelper createOrUpdateCategoryForRemoteCategory:remoteCategory blog:post.blog context:managedObjectContext];
        if (category) {
            [categories addObject:category];
        }
    }
}

+ (void)updateCommentsForPost:(AbstractPost *)post
{
    NSMutableSet *currentComments = [post mutableSetValueForKey:@"comments"];
    NSSet *allComments = [post.blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID = %@", post.postID]];
    [currentComments unionSet:allComments];
}

+ (NSDictionary *)dictionaryWithKey:(NSString *)key inMetadata:(NSArray *)metadata {
    NSArray *matchingEntries = [metadata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key = %@", key]];
    // In theory, there shouldn't be duplicated fields, but I've seen some bugs where there's more than one geo_* value
    // In any case, they should be sorted by id, so `lastObject` should have the newer value
    return [matchingEntries lastObject];
}

+ (NSArray *)remoteMetadataForPost:(Post *)post
{
    NSMutableArray *metadata = [NSMutableArray arrayWithCapacity:5];

    /// Send UUID as a foreign ID in metadata so we have a way to deduplicate new posts
    if (post.foreignID) {
        NSMutableDictionary *uuidDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        uuidDictionary[@"key"] = [self foreignIDKey];
        uuidDictionary[@"value"] = [post.foreignID UUIDString];
        [metadata addObject:uuidDictionary];
    }

    if (post.publicID) {
        NSMutableDictionary *publicDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        publicDictionary[@"id"] = [post.publicID numericValue];
        [metadata addObject:publicDictionary];
    }

    if (post.publicizeMessageID || post.publicizeMessage.length) {
        NSMutableDictionary *publicizeMessageDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        if (post.publicizeMessageID) {
            publicizeMessageDictionary[@"id"] = post.publicizeMessageID;
        }
        publicizeMessageDictionary[@"key"] = @"_wpas_mess";
        publicizeMessageDictionary[@"value"] = post.publicizeMessage.length ? post.publicizeMessage : @"";
        [metadata addObject:publicizeMessageDictionary];
    }

    [metadata addObjectsFromArray:[PostHelper publicizeMetadataEntriesForPost:post]];

    if (post.bloggingPromptID) {
        NSMutableDictionary *promptDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        promptDictionary[@"key"] = @"_jetpack_blogging_prompt_key";
        promptDictionary[@"value"] = post.bloggingPromptID;
        [metadata addObject:promptDictionary];
    }

    return metadata;
}

+ (NSArray *)mergePosts:(NSArray <RemotePost *> *)remotePosts
                 ofType:(NSString *)syncPostType
           withStatuses:(NSArray *)statuses
               byAuthor:(NSNumber *)authorID
                forBlog:(Blog *)blog
          purgeExisting:(BOOL)purge
              inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:remotePosts.count];
    for (RemotePost *remotePost in remotePosts) {
        AbstractPost *post = [blog lookupPostWithID:remotePost.postID inContext:context];
        if (post == nil) {
            NSUUID *foreignID = [PostHelper getForeignIDFor:remotePost];
            if (foreignID != nil) {
                post = [blog lookupLocalPostWithForeignID:foreignID inContext:context];
            }
        }
        if (!post) {
            if ([remotePost.type isEqualToString:PostServiceTypePage]) {
                // Create a Page entity for posts with a remote type of "page"
                post = [blog createPage];
            } else {
                // Create a Post entity for any other posts that have a remote post type of "post" or a custom post type.
                post = [blog createPost];
            }
        }
        [PostHelper updatePost:post withRemotePost:remotePost inContext:context];
        [posts addObject:post];
    }

    if (purge) {
        // Set up predicate for fetching any posts that could be purged for the sync.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(postID != NULL) AND (original = NULL) AND (revision = NULL) AND (blog = %@)", blog];
        if ([statuses count] > 0) {
            NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"status IN %@", statuses];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, statusPredicate]];
        }
        if (authorID) {
            NSPredicate *authorPredicate = [NSPredicate predicateWithFormat:@"authorID = %@", authorID];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, authorPredicate]];
        }

        NSFetchRequest *request;
        if ([syncPostType isEqualToString:PostServiceTypeAny]) {
            // If syncing "any" posts, set up the fetch for any AbstractPost entities (including child entities).
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([AbstractPost class])];
        } else if ([syncPostType isEqualToString:PostServiceTypePage]) {
            // If syncing "page" posts, set up the fetch for any Page entities.
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Page class])];
        } else {
            // If not syncing "page" or "any" post, use the Post entity.
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
            // Include the postType attribute in the predicate.
            NSPredicate *postTypePredicate = [NSPredicate predicateWithFormat:@"postType = %@", syncPostType];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, postTypePredicate]];
        }
        request.predicate = predicate;

        NSError *error;
        NSArray *existingPosts = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"Error fetching existing posts for purging: %@", error);
        } else {
            NSSet *postsToKeep = [NSSet setWithArray:posts];
            NSMutableSet *postsToDelete = [NSMutableSet setWithArray:existingPosts];
            // Delete the posts not being updated.
            [postsToDelete minusSet:postsToKeep];
            for (AbstractPost *post in postsToDelete) {
                DDLogInfo(@"Deleting Post: %@", post);
                [context deleteObject:post];
            }
        }
    }

    return posts;
}

+ (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost
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
    post.date_created_gmt = [NSDate dateFromServerDate:remotePost.date_created_gmt];
    post.featuredImage = remotePost.featuredImage;
    post.feedID = remotePost.feedID;
    post.feedItemID = remotePost.feedItemID;
    post.globalID = remotePost.globalID;
    post.isBlogAtomic = remotePost.isBlogAtomic;
    post.isBlogPrivate = remotePost.isBlogPrivate;
    post.isFollowing = remotePost.isFollowing;
    post.isLiked = remotePost.isLiked;
    post.isReblogged = remotePost.isReblogged;
    post.useExcerpt = remotePost.useExcerpt;
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

    // auto-suggested image, but NOT an explcitly specified featured image
    post.pathForDisplayImage = remotePost.autoSuggestedFeaturedImage;

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
        return SourcePostAttribution.site;
    }

    if ([taxonomies containsObject:SourceAttributionImageTaxonomy] ||
        [taxonomies containsObject:SourceAttributionQuoteTaxonomy] ||
        [taxonomies containsObject:SourceAttributionStandardTaxonomy] ) {
        return SourcePostAttribution.post;
    }

    return nil;
}

@end
