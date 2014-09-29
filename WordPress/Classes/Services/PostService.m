#import "PostService.h"
#import "Post.h"
#import "Coordinate.h"
#import "Category.h"
#import "Page.h"
#import "PostServiceRemote.h"
#import "PostServiceRemoteREST.h"
#import "PostServiceRemoteXMLRPC.h"
#import "RemotePost.h"
#import "RemoteCategory.h"
#import "CategoryService.h"
#import "ContextManager.h"

NSString * const PostServiceTypePost = @"post";
NSString * const PostServiceTypePage = @"page";
NSString * const PostServiceTypeAny = @"any";

@interface PostService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation PostService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

- (Post *)createPostForBlog:(Blog *)blog {
    NSAssert(self.managedObjectContext == blog.managedObjectContext, @"Blog's context should be the the same as the service's");
    Post *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Post class]) inManagedObjectContext:self.managedObjectContext];
    post.blog = blog;
    post.remoteStatus = AbstractPostRemoteStatusSync;
    return post;
}

- (Post *)createDraftPostForBlog:(Blog *)blog {
    Post *post = [self createPostForBlog:blog];
    [self initializeDraft:post];
    return post;
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

- (void)syncPostsOfType:(NSString *)postType
                forBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *))failure
{
    id<PostServiceRemote> remote = [self remoteForBlog:blog];
    [remote getPostsOfType:postType
                   forBlog:blog
                   success:^(NSArray *posts) {
                       [self.managedObjectContext performBlock:^{
                           [self mergePosts:posts ofType:postType forBlog:blog purgeExisting:YES completionHandler:success];
                       }];
                   } failure:^(NSError *error) {
                       if (failure) {
                           [self.managedObjectContext performBlock:^{
                               failure(error);
                           }];
                       }
                   }];
}

- (void)loadMorePostsOfType:(NSString *)postType
                    forBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *))failure
{
    id<PostServiceRemote> remote = [self remoteForBlog:blog];
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if ([remote isKindOfClass:[PostServiceRemoteREST class]]) {
        NSSet *postsWithDate = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"date_created_gmt != NULL"]];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:YES];
        Post *oldestPost = [[postsWithDate sortedArrayUsingDescriptors:@[sortDescriptor]] firstObject];
        // FIXME: convert date to JSON format?
        if (oldestPost.date_created_gmt) {
            options[@"before"] = oldestPost.date_created_gmt;
        }
    } else if ([remote isKindOfClass:[PostServiceRemoteXMLRPC class]]) {
        NSUInteger postCount = [blog.posts count];
        postCount += 40;
        options[@"number"] = @(postCount);
    }
    [remote getPostsOfType:postType
                   forBlog:blog
                   success:^(NSArray *posts) {
        [self.managedObjectContext performBlock:^{
            [self mergePosts:posts ofType:postType forBlog:blog purgeExisting:NO completionHandler:success];
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
                   forBlog:post.blog
                   success:successBlock
                   failure:failureBlock];
    } else {
        [remote createPost:remotePost
                   forBlog:post.blog
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
        [remote deletePost:remotePost forBlog:post.blog success:success failure:failure];
    }
    [self.managedObjectContext deleteObject:post];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

#pragma mark -

- (void)initializeDraft:(AbstractPost *)post {
    post.remoteStatus = AbstractPostRemoteStatusLocal;
    post.status = @"publish";
}

- (void)mergePosts:(NSArray *)posts ofType:(NSString *)postType forBlog:(Blog *)blog purgeExisting:(BOOL)purge completionHandler:(void (^)(void))completion {
    NSMutableArray *postsToKeep = [NSMutableArray array];
    for (RemotePost *remotePost in posts) {
        AbstractPost *post = [self findPostWithID:remotePost.postID inBlog:blog];
        if (!post) {
            if ([postType isEqualToString:PostServiceTypeAny]) {
                postType = remotePost.type;
            }
            if ([postType isEqualToString:PostServiceTypePage]) {
                post = [self createPageForBlog:blog];
            } else {
                post = [self createPostForBlog:blog];
            }
        }
        [self updatePost:post withRemotePost:remotePost];
        [postsToKeep addObject:post];
    }

    if (purge && ! [postType isEqualToString:PostServiceTypeAny]) {
        NSFetchRequest *request;
        if ([postType isEqualToString:PostServiceTypePage]) {
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Page class])];
        } else {
            request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
        }
        request.predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original == NULL) AND (blog = %@)", @(AbstractPostRemoteStatusSync), blog];
        NSArray *existingPosts = [self.managedObjectContext executeFetchRequest:request error:nil];
        if (existingPosts.count > 0) {
            for (AbstractPost *post in existingPosts) {
                if(![postsToKeep containsObject:post]) {
                    DDLogInfo(@"Deleting Post: %@", post);
                    [self.managedObjectContext deleteObject:post];
                }
            }
        }
    }

    [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext];

    if (completion) {
        completion();
    }
}

- (AbstractPost *)findPostWithID:(NSNumber *)postID inBlog:(Blog *)blog {
    NSSet *posts = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"original = NULL AND postID = %@", postID]];
    return [posts anyObject];
}

- (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost {
    post.postID = remotePost.postID;
    post.author = remotePost.authorDisplayName;
    post.date_created_gmt = remotePost.date;
    post.postTitle = remotePost.title;
    post.permaLink = [remotePost.URL absoluteString];
    post.content = remotePost.content;
    post.status = remotePost.status;
    post.password = remotePost.password;
    post.post_thumbnail = remotePost.postThumbnailID;
    if ([post isKindOfClass:[Page class]]) {
        Page *pagePost = (Page *)post;
        pagePost.parentID = remotePost.parentID;
    } else if ([post isKindOfClass:[Post class]]) {
        Post *postPost = (Post *)post;
        postPost.postFormat = remotePost.format;
        postPost.tags = [remotePost.tags componentsJoinedByString:@","];
        [self updatePost:postPost withRemoteCategories:remotePost.categories];

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
                Coordinate *c = [[Coordinate alloc] initWithCoordinate:coord];
                postPost.geolocation = c;
                postPost.latitudeID = [latitudeDictionary stringForKey:@"id"];
                postPost.longitudeID = [longitudeDictionary stringForKey:@"id"];
                postPost.publicID = [geoPublicDictionary stringForKey:@"id"];
            }
        }
    }
}

- (RemotePost *)remotePostWithPost:(AbstractPost *)post
{
    RemotePost *remotePost = [RemotePost new];
    remotePost.postID = post.postID;
    remotePost.date = post.date_created_gmt;
    remotePost.title = post.postTitle;
    remotePost.content = post.content;
    remotePost.status = post.status;
    remotePost.postThumbnailID = post.post_thumbnail;
    remotePost.password = post.password;
    remotePost.type = @"post";
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
        // TODO: metadata/geolocation
    }

    return remotePost;
}

- (NSArray *)remoteCategoriesForPost:(Post *)post
{
    NSMutableArray *remoteCategories = [NSMutableArray arrayWithCapacity:post.categories.count];
    for (Category *category in post.categories) {
        [remoteCategories addObject:[self remoteCategoryWithCategory:category]];
    }
    return [NSArray arrayWithArray:remoteCategories];
}

- (RemoteCategory *)remoteCategoryWithCategory:(Category *)category
{
    RemoteCategory *remoteCategory = [RemoteCategory new];
    remoteCategory.categoryID = category.categoryID;
    remoteCategory.name = category.categoryName;
    remoteCategory.parentID = category.parentID;
    return remoteCategory;
}

- (void)updatePost:(Post *)post withRemoteCategories:(NSArray *)remoteCategories {
    NSManagedObjectID *blogObjectID = post.blog.objectID;
    CategoryService *categoryService = [[CategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSMutableSet *categories = [post mutableSetValueForKey:@"categories"];
    [categories removeAllObjects];
    for (RemoteCategory *remoteCategory in remoteCategories) {
        Category *category = [categoryService findWithBlogObjectID:blogObjectID andCategoryID:remoteCategory.categoryID];
        if (!category) {
            category = [categoryService newCategoryForBlogObjectID:blogObjectID];
            category.categoryID = remoteCategory.categoryID;
            category.categoryName = remoteCategory.name;
            category.parentID = remoteCategory.parentID;
        }
        [categories addObject:category];
    }
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
        remote = [[PostServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:blog.xmlrpc]];
        remote = [[PostServiceRemoteXMLRPC alloc] initWithApi:client];
    }
    return remote;
}

@end
