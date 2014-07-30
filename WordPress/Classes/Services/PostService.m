#import "PostService.h"
#import "Post.h"
#import "Page.h"
#import "PostServiceRemote.h"
#import "PostServiceRemoteREST.h"
#import "PostServiceRemoteXMLRPC.h"
#import "RemotePost.h"
#import "RemoteCategory.h"
#import "CategoryService.h"
#import "ContextManager.h"

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
    return page;
}

- (Page *)createDraftPageForBlog:(Blog *)blog {
    Page *page = [self createPageForBlog:blog];
    [self initializeDraft:page];
    return page;
}

- (void)syncPostsForBlog:(Blog *)blog
                 success:(void (^)())success
                 failure:(void (^)(NSError *))failure {
    id<PostServiceRemote> remote = [self remoteForBlog:blog];
    [remote getPostsForBlog:blog
                    success:^(NSArray *posts) {
                        [self.managedObjectContext performBlock:^{
                            [self mergePosts:posts forBlog:blog purgeExisting:YES completionHandler:success];
                        }];
                    } failure:^(NSError *error) {
                        if (failure) {
                            [self.managedObjectContext performBlock:^{
                                failure(error);
                            }];
                        }
                    }];
}

- (void)loadMorePostsForBlog:(Blog *)blog
                     success:(void (^)())success
                     failure:(void (^)(NSError *))failure {
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
    [remote getPostsForBlog:blog options:options success:^(NSArray *posts) {
        [self.managedObjectContext performBlock:^{
            [self mergePosts:posts forBlog:blog purgeExisting:NO completionHandler:success];
        }];
    } failure:^(NSError *error) {
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }
    }];
}

#pragma mark -

- (void)initializeDraft:(AbstractPost *)post {
    post.remoteStatus = AbstractPostRemoteStatusLocal;
    post.status = @"publish";
}

- (void)mergePosts:(NSArray *)posts forBlog:(Blog *)blog purgeExisting:(BOOL)purge completionHandler:(void (^)(void))completion {
    NSMutableArray *postsToKeep = [NSMutableArray array];
    for (RemotePost *remotePost in posts) {
        Post *post = [self findPostWithID:remotePost.postID inBlog:blog];
        if (!post) {
            post = [self createPostForBlog:blog];
        }
        [self updatePost:post withRemotePost:remotePost];
        [postsToKeep addObject:post];
    }

    if (purge) {
        NSSet *existingPosts = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original == NULL)", @(AbstractPostRemoteStatusSync)]];
        if (existingPosts.count > 0) {
            for (Post *post in existingPosts) {
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

- (Post *)findPostWithID:(NSNumber *)postID inBlog:(Blog *)blog {
    NSSet *posts = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"original = NULL AND postID = %@", postID]];
    return [posts anyObject];
}

- (void)updatePost:(Post *)post withRemotePost:(RemotePost *)remotePost {
    post.postID = remotePost.postID;
    post.author = remotePost.authorDisplayName;
    post.date_created_gmt = remotePost.date;
    post.postTitle = remotePost.title;
    post.permaLink = [remotePost.URL absoluteString];
    post.content = remotePost.content;
    post.status = remotePost.status;
    post.password = remotePost.password;
    post.postFormat = remotePost.format;
    post.tags = [remotePost.tags componentsJoinedByString:@","];
    [self updatePost:post withRemoteCategories:remotePost.categories];

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
            post.geolocation = c;
            post.latitudeID = [latitudeDictionary stringForKey:@"id"];
            post.longitudeID = [latitudeDictionary stringForKey:@"id"];
            post.publicID = [geoPublicDictionary stringForKey:@"id"];
        }
    }
    post.post_thumbnail = remotePost.postThumbnailID;
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
