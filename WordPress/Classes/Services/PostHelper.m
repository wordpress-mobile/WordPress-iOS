#import "PostHelper.h"
#import "AbstractPost.h"
#import "WordPress-Swift.h"

@import WordPressKit;

@implementation PostService (PostHelper)

- (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost {
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
        [self updatePost:postPost withRemoteCategories:remotePost.categories];

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

- (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories {
    NSManagedObjectID *blogObjectID = post.blog.objectID;
    NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
    [categories removeAllObjects];
    for (RemotePostCategory *remoteCategory in remoteCategories) {
        PostCategory *category = [PostCategory lookupWithBlogObjectID:blogObjectID categoryID:remoteCategory.categoryID inContext:self.managedObjectContext];
        if (!category) {
            category = [PostCategory createWithBlogObjectID:blogObjectID inContext:self.managedObjectContext];
            category.categoryID = remoteCategory.categoryID;
            category.categoryName = remoteCategory.name;
            category.parentID = remoteCategory.parentID;
        }
        [categories addObject:category];
    }
}

- (void)updateCommentsForPost:(AbstractPost *)post
{
    NSMutableSet *currentComments = [post mutableSetValueForKey:@"comments"];
    NSSet *allComments = [post.blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID = %@", post.postID]];
    [currentComments unionSet:allComments];
}

- (NSDictionary *)dictionaryWithKey:(NSString *)key inMetadata:(NSArray *)metadata {
    NSArray *matchingEntries = [metadata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key = %@", key]];
    // In theory, there shouldn't be duplicated fields, but I've seen some bugs where there's more than one geo_* value
    // In any case, they should be sorted by id, so `lastObject` should have the newer value
    return [matchingEntries lastObject];
}

@end
