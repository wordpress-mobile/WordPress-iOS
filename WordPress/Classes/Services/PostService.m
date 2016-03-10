#import "PostService.h"
#import "Post.h"
#import "Coordinate.h"
#import "PostCategory.h"
#import "Page.h"
#import "PostServiceRemote.h"
#import "PostServiceRemoteREST.h"
#import "PostServiceRemoteXMLRPC.h"
#import "RemotePost.h"
#import "RemotePostCategory.h"
#import "PostCategoryService.h"
#import "ContextManager.h"
#import "NSDate+WordPressJSON.h"
#import "CommentService.h"
#import "WordPress-Swift.h"

NSString * const PostServiceTypePost = @"post";
NSString * const PostServiceTypePage = @"page";
NSString * const PostServiceTypeAny = @"any";
NSString * const PostServiceErrorDomain = @"PostServiceErrorDomain";

const NSUInteger PostServiceDefaultNumberToSync = 40;

@implementation PostService

+ (instancetype)serviceWithMainContext {
    return [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
}

- (Post *)createPostForBlog:(Blog *)blog {
    NSAssert(self.managedObjectContext == blog.managedObjectContext, @"Blog's context should be the the same as the service's");
    Post *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Post class]) inManagedObjectContext:self.managedObjectContext];
    post.blog = blog;
    post.remoteStatus = AbstractPostRemoteStatusSync;
    PostCategoryService *postCategoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    PostCategory *category = [postCategoryService findWithBlogObjectID:blog.objectID andCategoryID:blog.settings.defaultCategoryID];
    if (category) {
        [post addCategoriesObject:category];
    }
    post.postFormat = blog.settings.defaultPostFormat;
    post.postType = PostTypeDefaultIdentifier;
    return post;
}

- (Post *)createDraftPostForBlog:(Blog *)blog {
    Post *post = [self createPostForBlog:blog];
    [self initializeDraft:post];
    return post;
}

+ (Post *)createDraftPostInMainContextForBlog:(Blog *)blog {
    PostService *service = [PostService serviceWithMainContext];
    return [service createDraftPostForBlog:blog];
}

- (Page *)createPageForBlog:(Blog *)blog {
    NSAssert(self.managedObjectContext == blog.managedObjectContext, @"Blog's context should be the the same as the service's");
    Page *page = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Page class]) inManagedObjectContext:self.managedObjectContext];
    page.blog = blog;
    page.remoteStatus = AbstractPostRemoteStatusSync;
    return page;
}

- (Page *)createDraftPageForBlog:(Blog *)blog {
    Page *page = [self createPageForBlog:blog];
    [self initializeDraft:page];
    return page;
}

+ (Page *)createDraftPageInMainContextForBlog:(Blog *)blog {
    PostService *service = [PostService serviceWithMainContext];
    return [service createDraftPageForBlog:blog];
}

- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(AbstractPost *post))success
              failure:(void (^)(NSError *))failure
{
    id<PostServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogID = blog.objectID;
    [remote getPostWithID:postID
                  success:^(RemotePost *remotePost){
                      [self.managedObjectContext performBlock:^{
                          Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
                          if (!blog) {
                              return;
                          }
                          if (remotePost) {
                              AbstractPost *post = [self findPostWithID:postID inBlog:blog];
                              if (!post) {
                                  post = [self createPostForBlog:blog];
                              }
                              [self updatePost:post withRemotePost:remotePost];
                              [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

                              if (success) {
                                  success(post);
                              }
                          }
                          else if (failure) {
                              NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Retrieved remote post is nil" };
                              failure([NSError errorWithDomain:PostServiceErrorDomain code:0 userInfo:userInfo]);
                          }
                      }];
                  }
                  failure:^(NSError *error) {
                      if (failure) {
                          [self.managedObjectContext performBlock:^{
                              failure(error);
                          }];
                      }
                  }];
}

- (void)syncPostsOfType:(NSString *)postType
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure
{
    [self syncPostsOfType:postType
              withOptions:nil
                  forBlog:blog
                  success:success
                  failure:failure];
}

- (void)syncPostsOfType:(NSString *)postType
                withOptions:(PostServiceSyncOptions *)options
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<PostServiceRemote> remote = [self remoteForBlog:blog];

    NSDictionary *remoteOptions = options ? [self remoteSyncParametersDictionaryForRemote:remote withOptions:options] : nil;
    [remote getPostsOfType:postType
                   options:remoteOptions
                   success:^(NSArray <RemotePost *> *remotePosts) {
                       [self.managedObjectContext performBlock:^{
                           NSError *error;
                           Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
                           if (!blogInContext || error) {
                               DDLogError(@"Could not retrieve blog in context %@", (error ? [NSString stringWithFormat:@"with error: %@", error] : @""));
                               return;
                           }
                           [self mergePosts:remotePosts
                                     ofType:postType
                               withStatuses:options.statuses
                                   byAuthor:options.authorID
                                    forBlog:blogInContext
                              purgeExisting:options.purgesLocalSync
                          completionHandler:^(NSArray<AbstractPost *> *posts) {
                              if (success) {
                                  success(posts);
                              }
                          }];
                       }];
                   } failure:^(NSError *error) {
                       if (failure) {
                           [self.managedObjectContext performBlock:^{
                               failure(error);
                           }];
                       }
                   }];
}

- (void)uploadPost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure
{
    id<PostServiceRemote> remote = [self remoteForBlog:post.blog];
    RemotePost *remotePost = [self remotePostWithPost:post];

    post.remoteStatus = AbstractPostRemoteStatusPushing;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    NSManagedObjectID *postObjectID = post.objectID;
    void (^successBlock)(RemotePost *post) = ^(RemotePost *post) {
        [self.managedObjectContext performBlock:^{
            Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:nil];
            if (postInContext) {
                [self updatePost:postInContext withRemotePost:post];
                postInContext.remoteStatus = AbstractPostRemoteStatusSync;
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (success) {
                success();
            }
        }];
    };
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:nil];
            if (postInContext) {
                postInContext.remoteStatus = AbstractPostRemoteStatusFailed;
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (failure) {
                failure(error);
            }
        }];
    };

    if ([post.postID longLongValue] > 0) {
        [remote updatePost:remotePost
                   success:successBlock
                   failure:failureBlock];
    } else {
        [remote createPost:remotePost
                   success:successBlock
                   failure:failureBlock];
    }
}

- (void)deletePost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure
{
    NSNumber *postID = post.postID;
    if ([postID longLongValue] > 0) {
        RemotePost *remotePost = [self remotePostWithPost:post];
        id<PostServiceRemote> remote = [self remoteForBlog:post.blog];
        [remote deletePost:remotePost success:success failure:failure];
    }
    [self.managedObjectContext deleteObject:post];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)trashPost:(AbstractPost *)post
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure
{
    NSNumber *postID = post.postID;
    if ([postID longLongValue] <= 0 || [post.status isEqualToString:PostStatusTrash]) {
        // Local draft, or a trashed post. Hand off to the delete method.
        [self deletePost:post success:success failure:failure];
        return;
    }

    post.restorableStatus = post.status;
    NSManagedObjectID *postObjectID = post.objectID;
    void (^successBlock)(RemotePost *post) = ^(RemotePost *remotePost) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            if (!remotePost || [remotePost.status isEqualToString:PostStatusDeleted]) {
                [self.managedObjectContext deleteObject:post];
            } else {
                [self updatePost:postInContext withRemotePost:remotePost];
            }
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
        if (success) {
            success();
        }
    };

    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            postInContext.restorableStatus = nil;
        }
        if (failure){
            failure(error);
        }
    };

    RemotePost *remotePost = [self remotePostWithPost:post];
    id<PostServiceRemote> remote = [self remoteForBlog:post.blog];
    [remote trashPost:remotePost success:successBlock failure:failureBlock];
}

- (void)restorePost:(AbstractPost *)post
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    if (post.restorableStatus) {
        // Optimistically update and save.
        post.status = post.restorableStatus;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }

    void (^successBlock)(RemotePost *post) = ^(RemotePost *remotePost) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        postInContext.restorableStatus = nil;
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            [self updatePost:postInContext withRemotePost:remotePost];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
        if (success) {
            success();
        }
    };

    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        NSError *err;
        Post *postInContext = (Post *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
        if (err) {
            DDLogError(@"%@", err);
        }
        if (postInContext) {
            // Put the post back in the trash bin.
            postInContext.status = PostStatusTrash;
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
        if (failure){
            failure(error);
        }
    };

    RemotePost *remotePost = [self remotePostWithPost:post];
    if (post.restorableStatus) {
        remotePost.status = post.restorableStatus;
    } else {
        // Assign a status of draft to the remote post. The WordPress.com REST API will
        // ignore this and should restore the post's previous status. The XML-RPC API
        // needs a status assigned to move a post out of the trash folder. Draft is the
        // safest option when we don't know what the status was previously.
        remotePost.status = PostStatusDraft;
    }

    id<PostServiceRemote> remote = [self remoteForBlog:post.blog];
    [remote restorePost:remotePost success:successBlock failure:failureBlock];
}

#pragma mark - Helpers

- (void)initializeDraft:(AbstractPost *)post {
    post.remoteStatus = AbstractPostRemoteStatusLocal;
}

- (void)mergePosts:(NSArray <RemotePost *> *)remotePosts
            ofType:(NSString *)syncPostType
      withStatuses:(NSArray *)statuses
          byAuthor:(NSNumber *)authorID
           forBlog:(Blog *)blog
     purgeExisting:(BOOL)purge
 completionHandler:(void (^)(NSArray <AbstractPost *> *posts))completion
{
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:remotePosts.count];
    for (RemotePost *remotePost in remotePosts) {
        AbstractPost *post = [self findPostWithID:remotePost.postID inBlog:blog];
        if (!post) {
            if ([remotePost.type isEqualToString:PostServiceTypePage]) {
                // Create a Page entity for posts with a remote type of "page"
                post = [self createPageForBlog:blog];
            } else {
                // Create a Post entity for any other posts that have a remote post type of "post" or a custom post type.
                post = [self createPostForBlog:blog];
            }
        }
        [self updatePost:post withRemotePost:remotePost];
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
        NSArray *existingPosts = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"Error fetching existing posts for purging: %@", error);
        } else {
            NSSet *postsToKeep = [NSSet setWithArray:posts];
            NSMutableSet *postsToDelete = [NSMutableSet setWithArray:existingPosts];
            // Delete the posts not being updated.
            [postsToDelete minusSet:postsToKeep];
            for (AbstractPost *post in postsToDelete) {
                DDLogInfo(@"Deleting Post: %@", post);
                [self.managedObjectContext deleteObject:post];
            }
        }
    }
    
    [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext];
    if (completion) {
        completion(posts);
    }
}

- (AbstractPost *)findPostWithID:(NSNumber *)postID inBlog:(Blog *)blog {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([AbstractPost class])];
    request.predicate = [NSPredicate predicateWithFormat:@"blog = %@ AND original = NULL AND postID = %@", blog, postID];
    NSArray *posts = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [posts firstObject];
}

- (NSDictionary *)remoteSyncParametersDictionaryForRemote:(nonnull id <PostServiceRemote>)remote
                                              withOptions:(nonnull PostServiceSyncOptions *)options
{
    return [remote dictionaryWithRemoteOptions:options];
}

- (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost {
    NSNumber *previousPostID = post.postID;
    post.postID = remotePost.postID;
    post.author = remotePost.authorDisplayName;
    post.authorID = remotePost.authorID;
    post.date_created_gmt = remotePost.date;
    post.postTitle = remotePost.title;
    post.permaLink = [remotePost.URL absoluteString];
    post.content = remotePost.content;
    post.status = remotePost.status;
    post.password = remotePost.password;
    post.post_thumbnail = remotePost.postThumbnailID;
    post.pathForDisplayImage = remotePost.pathForDisplayImage;
    post.authorAvatarURL = remotePost.authorAvatarURL;
    post.mt_excerpt = remotePost.excerpt;

    if (remotePost.postID != previousPostID) {
        [self updateCommentsForPost:post];
    }

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
        [self updatePost:postPost withRemoteCategories:remotePost.categories];

        Coordinate *geolocation = nil;
        NSString *latitudeID = nil;
        NSString *longitudeID = nil;
        NSString *publicID = nil;
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
                geolocation = [[Coordinate alloc] initWithCoordinate:coord];
                latitudeID = [latitudeDictionary stringForKey:@"id"];
                longitudeID = [longitudeDictionary stringForKey:@"id"];
                publicID = [geoPublicDictionary stringForKey:@"id"];
            }
        }
        postPost.geolocation = geolocation;
        postPost.latitudeID = latitudeID;
        postPost.longitudeID = longitudeID;
        postPost.publicID = publicID;
    }
}

- (RemotePost *)remotePostWithPost:(AbstractPost *)post
{
    RemotePost *remotePost = [RemotePost new];
    remotePost.postID = post.postID;
    remotePost.date = post.date_created_gmt;
    remotePost.title = post.postTitle ?: @"";
    remotePost.content = post.content;
    remotePost.status = post.status;
    remotePost.postThumbnailID = post.post_thumbnail;
    remotePost.password = post.password;
    remotePost.type = @"post";
    remotePost.authorAvatarURL = post.authorAvatarURL;

    if ([post isKindOfClass:[Page class]]) {
        Page *pagePost = (Page *)post;
        remotePost.parentID = pagePost.parentID;
        remotePost.type = @"page";
    }
    if ([post isKindOfClass:[Post class]]) {
        Post *postPost = (Post *)post;
        remotePost.format = postPost.postFormat;
        remotePost.tags = [postPost.tags componentsSeparatedByString:@","];
        remotePost.categories = [self remoteCategoriesForPost:postPost];
        remotePost.metadata = [self remoteMetadataForPost:postPost];
    }

    remotePost.isFeaturedImageChanged = post.isFeaturedImageChanged;

    return remotePost;
}

- (NSArray *)remoteCategoriesForPost:(Post *)post
{
    return [[post.categories allObjects] wp_map:^id(PostCategory *category) {
        return [self remoteCategoryWithCategory:category];
    }];
}

- (RemotePostCategory *)remoteCategoryWithCategory:(PostCategory *)category
{
    RemotePostCategory *remoteCategory = [RemotePostCategory new];
    remoteCategory.categoryID = category.categoryID;
    remoteCategory.name = category.categoryName;
    remoteCategory.parentID = category.parentID;
    return remoteCategory;
}

- (NSArray *)remoteMetadataForPost:(Post *)post {
    NSMutableArray *metadata = [NSMutableArray arrayWithCapacity:3];
    Coordinate *c = post.geolocation;

    /*
     This might look more complicated than it should be, but it needs to be that way.

     Depending of the existence of geolocation and ID values, we need to add/update/delete the custom fields:
     - geolocation  &&  ID: update
     - geolocation  && !ID: add
     - !geolocation &&  ID: delete
     - !geolocation && !ID: noop
     */
    if (post.latitudeID || c) {
        NSMutableDictionary *latitudeDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        if (post.latitudeID) {
            latitudeDictionary[@"id"] = [post.latitudeID numericValue];
        }
        if (c) {
            latitudeDictionary[@"key"] = @"geo_latitude";
            latitudeDictionary[@"value"] = @(c.latitude);
        }
        [metadata addObject:latitudeDictionary];
    }
    if (post.longitudeID || c) {
        NSMutableDictionary *longitudeDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        if (post.latitudeID) {
            longitudeDictionary[@"id"] = [post.longitudeID numericValue];
        }
        if (c) {
            longitudeDictionary[@"key"] = @"geo_longitude";
            longitudeDictionary[@"value"] = @(c.longitude);
        }
        [metadata addObject:longitudeDictionary];
    }
    if (post.publicID || c) {
        NSMutableDictionary *publicDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        if (post.publicID) {
            publicDictionary[@"id"] = [post.publicID numericValue];
        }
        if (c) {
            publicDictionary[@"key"] = @"geo_public";
            publicDictionary[@"value"] = @1;
        }
        [metadata addObject:publicDictionary];
    }
    return metadata;
}

- (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories {
    NSManagedObjectID *blogObjectID = post.blog.objectID;
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
    [categories removeAllObjects];
    for (RemotePostCategory *remoteCategory in remoteCategories) {
        PostCategory *category = [categoryService findWithBlogObjectID:blogObjectID andCategoryID:remoteCategory.categoryID];
        if (!category) {
            category = [categoryService newCategoryForBlogObjectID:blogObjectID];
            category.categoryID = remoteCategory.categoryID;
            category.categoryName = remoteCategory.name;
            category.parentID = remoteCategory.parentID;
        }
        [categories addObject:category];
    }
}

- (void)updateCommentsForPost:(AbstractPost *)post
{
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSMutableSet *currentComments = [post mutableSetValueForKey:@"comments"];
    NSSet *allComments = [commentService findCommentsWithPostID:post.postID inBlog:post.blog];
    [currentComments addObjectsFromArray:[allComments allObjects]];
}

- (NSDictionary *)dictionaryWithKey:(NSString *)key inMetadata:(NSArray *)metadata {
    NSArray *matchingEntries = [metadata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key = %@", key]];
    // In theory, there shouldn't be duplicated fields, but I've seen some bugs where there's more than one geo_* value
    // In any case, they should be sorted by id, so `lastObject` should have the newer value
    return [matchingEntries lastObject];
}

- (id<PostServiceRemote>)remoteForBlog:(Blog *)blog {
    id<PostServiceRemote> remote;
    if (blog.restApi) {
        remote = [[PostServiceRemoteREST alloc] initWithApi:blog.restApi siteID:blog.dotComID];
    } else {
        remote = [[PostServiceRemoteXMLRPC alloc] initWithApi:blog.api username:blog.username password:blog.password];
    }
    return remote;
}

@end
