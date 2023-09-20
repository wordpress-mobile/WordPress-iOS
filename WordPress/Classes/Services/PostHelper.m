#import "PostHelper.h"
#import "AbstractPost.h"
#import "WordPress-Swift.h"

@import WordPressKit;

@implementation PostHelper

+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)managedObjectContext {
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

    if ([remotePost.revisions wp_isValidObject]) {
        post.revisions = [remotePost.revisions copy];
    }

    if (remotePost.postID != previousPostID) {
        [self updateCommentsForPost:post];
    }

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

    post.statusAfterSync = post.status;
}

+ (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories inContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectID *blogObjectID = post.blog.objectID;
    NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
    [categories removeAllObjects];
    for (RemotePostCategory *remoteCategory in remoteCategories) {
        PostCategory *category = [PostCategory lookupWithBlogObjectID:blogObjectID categoryID:remoteCategory.categoryID inContext:managedObjectContext];
        if (!category) {
            category = [PostCategory createWithBlogObjectID:blogObjectID inContext:managedObjectContext];
            category.categoryID = remoteCategory.categoryID;
            category.categoryName = remoteCategory.name;
            category.parentID = remoteCategory.parentID;
        }
        [categories addObject:category];
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

+ (RemotePost *)remotePostWithPost:(AbstractPost *)post
{
    RemotePost *remotePost = [RemotePost new];
    remotePost.postID = post.postID;
    remotePost.date = post.date_created_gmt;
    remotePost.dateModified = post.dateModified;
    remotePost.title = post.postTitle ?: @"";
    remotePost.content = post.content;
    remotePost.status = post.status;
    if (post.featuredImage) {
        remotePost.postThumbnailID = post.featuredImage.mediaID;
    }
    remotePost.password = post.password;
    remotePost.type = @"post";
    remotePost.authorAvatarURL = post.authorAvatarURL;
    // If a Post's authorID is 0 (the default Core Data value)
    // or nil, don't send it to the API.
    if (post.authorID.integerValue != 0) {
        remotePost.authorID = post.authorID;
    }
    remotePost.excerpt = post.mt_excerpt;
    remotePost.slug = post.wp_slug;

    if ([post isKindOfClass:[Page class]]) {
        Page *pagePost = (Page *)post;
        remotePost.parentID = pagePost.parentID;
        remotePost.type = @"page";
    }
    if ([post isKindOfClass:[Post class]]) {
        Post *postPost = (Post *)post;
        remotePost.format = postPost.postFormat;
        remotePost.tags = [[postPost.tags componentsSeparatedByString:@","] wp_map:^id(NSString *obj) {
            return [obj stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        }];
        remotePost.categories = [self remoteCategoriesForPost:postPost];
        remotePost.metadata = [self remoteMetadataForPost:postPost];

        // Because we can't get what's the self-hosted non Jetpack site capabilities
        // only Admin users are allowed to set a post as sticky.
        // This doesn't affect WPcom sites.
        //
        BOOL canMarkPostAsSticky = ([post.blog supports:BlogFeatureWPComRESTAPI] || post.blog.isAdmin);
        remotePost.isStickyPost = canMarkPostAsSticky ? @(postPost.isStickyPost) : nil;
    }

    remotePost.isFeaturedImageChanged = post.isFeaturedImageChanged;

    return remotePost;
}

+ (NSArray *)remoteCategoriesForPost:(Post *)post
{
    return [[post.categories allObjects] wp_map:^id(PostCategory *category) {
        return [self remoteCategoryWithCategory:category];
    }];
}

+ (RemotePostCategory *)remoteCategoryWithCategory:(PostCategory *)category
{
    RemotePostCategory *remoteCategory = [RemotePostCategory new];
    remoteCategory.categoryID = category.categoryID;
    remoteCategory.name = category.categoryName;
    remoteCategory.parentID = category.parentID;
    return remoteCategory;
}

+ (NSArray *)remoteMetadataForPost:(Post *)post {
    NSMutableArray *metadata = [NSMutableArray arrayWithCapacity:4];

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
        NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original = NULL) AND (revision = NULL) AND (blog = %@)", @(AbstractPostRemoteStatusSync), blog];
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

@end
