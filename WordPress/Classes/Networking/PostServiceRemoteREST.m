#import "PostServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "DisplayableImageHelper.h"
#import "RemotePost.h"
#import "RemotePostCategory.h"
#import "NSDate+WordPressJSON.h"

@interface PostServiceRemoteREST ()

@property (nonatomic, strong) WordPressComApi *api;

@end

@implementation PostServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api {
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(RemotePost *post))success
              failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@", blog.dotComID, postID];
    NSDictionary *parameters = @{ @"context": @"edit" };
    [self.api GET:path
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remotePostFromJSONDictionary:responseObject]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
               success:(void (^)(NSArray *))success
               failure:(void (^)(NSError *))failure
{
    [self getPostsOfType:postType forBlog:blog options:nil success:success failure:failure];
}

- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
               options:(NSDictionary *)options
               success:(void (^)(NSArray *))success
               failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts", blog.dotComID];
    NSDictionary *parameters = @{
                                 @"status": @"any,trash",
                                 @"context": @"edit",
                                 @"number": @40,
                                 @"type": postType,
                                 };
    if (options) {
        NSMutableDictionary *mutableParameters = [parameters mutableCopy];
        [mutableParameters addEntriesFromDictionary:options];
        parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    }
    [self.api GET:path
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remotePostsFromJSONArray:responseObject[@"posts"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)createPost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/new?context=edit", blog.dotComID];
    NSDictionary *parameters = [self parametersWithRemotePost:post];

    [self.api POST:path
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               RemotePost *post = [self remotePostFromJSONDictionary:responseObject];
               if (success) {
                   success(post);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)updatePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@?context=edit", blog.dotComID, post.postID];
    NSDictionary *parameters = [self parametersWithRemotePost:post];

    [self.api POST:path
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               RemotePost *post = [self remotePostFromJSONDictionary:responseObject];
               if (success) {
                   success(post);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)deletePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)())success
           failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/delete", blog.dotComID, post.postID];
    [self.api POST:path
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)trashPost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure
{
    NSParameterAssert(post != nil);
    NSParameterAssert(blog != nil);
    NSParameterAssert(blog.dotComID != nil);
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/delete", blog.dotComID, post.postID];
    [self.api POST:path
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               RemotePost *post = [self remotePostFromJSONDictionary:responseObject];
               if (success) {
                   success(post);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)restorePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure
{
    NSParameterAssert(post != nil);
    NSParameterAssert(blog != nil);
    NSParameterAssert(blog.dotComID != nil);
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/restore", blog.dotComID, post.postID];
    [self.api POST:path
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               RemotePost *post = [self remotePostFromJSONDictionary:responseObject];
               if (success) {
                   success(post);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}


#pragma mark - Private methods

- (NSArray *)remotePostsFromJSONArray:(NSArray *)jsonPosts {
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:jsonPosts.count];
    for (NSDictionary *jsonPost in jsonPosts) {
        [posts addObject:[self remotePostFromJSONDictionary:jsonPost]];
    }
    return [NSArray arrayWithArray:posts];
}

- (RemotePost *)remotePostFromJSONDictionary:(NSDictionary *)jsonPost {
    RemotePost *post = [RemotePost new];
    post.postID = jsonPost[@"ID"];
    post.siteID = jsonPost[@"site_ID"];
    post.authorAvatarURL = jsonPost[@"author"][@"avatar_URL"];
    post.authorDisplayName = jsonPost[@"author"][@"name"];
    post.authorEmail = [jsonPost[@"author"] stringForKey:@"email"];
    post.authorURL = jsonPost[@"author"][@"URL"];
    post.authorID = [jsonPost numberForKeyPath:@"author.ID"];
    post.date = [NSDate dateWithWordPressComJSONString:jsonPost[@"date"]];
    post.title = jsonPost[@"title"];
    post.URL = [NSURL URLWithString:jsonPost[@"URL"]];
    post.shortURL = [NSURL URLWithString:jsonPost[@"short_URL"]];
    post.content = jsonPost[@"content"];
    post.excerpt = jsonPost[@"excerpt"];
    post.slug = jsonPost[@"slug"];
    post.status = jsonPost[@"status"];
    post.password = jsonPost[@"password"];
    if ([post.password isEmpty]) {
        post.password = nil;
    }
    post.parentID = [jsonPost numberForKeyPath:@"parent.ID"];
    // post_thumbnail can be null, which will transform to NSNull, so we need to add the extra check
    NSDictionary *postThumbnail = [jsonPost dictionaryForKey:@"post_thumbnail"];
    post.postThumbnailID = [postThumbnail numberForKey:@"ID"];
    post.postThumbnailPath = [postThumbnail stringForKeyPath:@"URL"];
    post.type = jsonPost[@"type"];
    post.format = jsonPost[@"format"];

    post.commentCount = [jsonPost numberForKeyPath:@"discussion.comment_count"] ?: @0;
    post.likeCount = [jsonPost numberForKeyPath:@"like_count"] ?: @0;

    // FIXME: remove conversion once API is fixed #38-io
    // metadata should always be an array but it's returning false when there are no custom fields
    post.metadata = [jsonPost arrayForKey:@"metadata"];
    // Or even worse, in some cases (Jetpack sites?) is an array containing false
    post.metadata = [post.metadata filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[NSDictionary class]];
    }]];
    // post.metadata = jsonPost[@"metadata"];

    NSDictionary *categories = jsonPost[@"categories"];
    if (categories) {
        post.categories = [self remoteCategoriesFromJSONArray:[categories allValues]];
    }
    post.tags = [self tagNamesFromJSONDictionary:jsonPost[@"tags"]];

    // Pick an image to use for display
    if (post.postThumbnailPath) {
        post.pathForDisplayImage = post.postThumbnailPath;
    } else {
        // check attachments for a suitable image
        post.pathForDisplayImage = [DisplayableImageHelper searchPostAttachmentsForImageToDisplay:[jsonPost dictionaryForKey:@"attachments"]];

        // parse contents for a suitable image
        if (!post.pathForDisplayImage) {
            post.pathForDisplayImage = [DisplayableImageHelper searchPostContentForImageToDisplay:post.content];
        }
    }

    return post;
}

- (NSDictionary *)parametersWithRemotePost:(RemotePost *)post
{
    NSParameterAssert(post.title != nil);
    NSParameterAssert(post.content != nil);
    BOOL existingPost = ([post.postID longLongValue] > 0);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (post.title) {
        parameters[@"title"] = post.title;
    } else {
        parameters[@"title"] = @"";
    }
    
    parameters[@"content"] = post.content;
    parameters[@"status"] = post.status;
    parameters[@"password"] = post.password ? post.password : @"";
    parameters[@"type"] = post.type;

    if (post.date) {
        parameters[@"date"] = [post.date WordPressComJSONString];
    } else if (existingPost) {
        parameters[@"date"] = [[NSDate date] WordPressComJSONString];
    }
    if (post.excerpt) {
        parameters[@"excerpt"] = post.excerpt;
    }
    if (post.slug) {
        parameters[@"slug"] = post.slug;
    }
    if (post.parentID) {
        parameters[@"parent"] = post.parentID;
    }

    if (post.categories) {
        parameters[@"categories"] = [post.categories valueForKey:@"categoryID"];
    }
    if (post.tags) {
        parameters[@"tags"] = post.tags;
    }
    if (post.format) {
        parameters[@"format"] = post.format;
    }
    parameters[@"featured_image"] = post.postThumbnailID ? [post.postThumbnailID stringValue] : @"";
    parameters[@"metadata"] = [self metadataForPost:post];

    // Test what happens for nil and not present values
    return [NSDictionary dictionaryWithDictionary:parameters];
}

- (NSArray *)metadataForPost:(RemotePost *)post {
    NSMutableArray *metadata = [NSMutableArray arrayWithCapacity:post.metadata.count];
    for (NSDictionary *meta in post.metadata) {
        NSNumber *metaID = [meta objectForKey:@"id"];
        NSString *metaValue = [meta objectForKey:@"value"];
        NSString *operation = @"update";
        if (metaID && !metaValue) {
            operation = @"delete";
        } else if (!metaID && metaValue) {
            operation = @"add";
        }
        NSMutableDictionary *modifiedMeta = [meta mutableCopy];
        modifiedMeta[@"operation"] = operation;
        [metadata addObject:[NSDictionary dictionaryWithDictionary:modifiedMeta]];
    }
    return [NSArray arrayWithArray:metadata];
}

- (NSArray *)remoteCategoriesFromJSONArray:(NSArray *)jsonCategories {
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:jsonCategories.count];
    for (NSDictionary *jsonCategory in jsonCategories) {
        [categories addObject:[self remoteCategoryFromJSONDictionary:jsonCategory]];
    }
    return [NSArray arrayWithArray:categories];
}

- (RemotePostCategory *)remoteCategoryFromJSONDictionary:(NSDictionary *)jsonCategory {
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = jsonCategory[@"ID"];
    category.name = jsonCategory[@"name"];
    category.parentID = jsonCategory[@"parent"];

    return category;
}

- (NSArray *)tagNamesFromJSONDictionary:(NSDictionary *)jsonTags {
    return [jsonTags allKeys];
}

@end
