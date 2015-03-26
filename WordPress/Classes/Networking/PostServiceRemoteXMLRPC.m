#import "PostServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemotePost.h"
#import "RemotePostCategory.h"
#import "NSMutableDictionary+Helpers.h"
#import <WordPressApi.h>

@interface PostServiceRemoteXMLRPC ()
@property (nonatomic, strong) WPXMLRPCClient *api;
@end

@implementation PostServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
{
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
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:postID];
    [self.api callMethod:@"wp.getPost"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (success) {
                         success([self remotePostFromXMLRPCDictionary:responseObject]);
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
               failure:(void (^)(NSError *))failure {
    [self getPostsOfType:postType forBlog:blog options:nil success:success failure:failure];
}

- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
               options:(NSDictionary *)options
               success:(void (^)(NSArray *posts))success
               failure:(void (^)(NSError *error))failure {
    NSDictionary *extraParameters = @{
                                      @"number": @40,
                                      @"post_type": postType,
                                      };
    if (options) {
        NSMutableDictionary *mutableParameters = [extraParameters mutableCopy];
        [mutableParameters addEntriesFromDictionary:options];
        extraParameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    }
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"wp.getPosts"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remotePostsFromXMLRPCArray:responseObject]);
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
    NSDictionary *extraParameters = [self parametersWithRemotePost:post];
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:extraParameters];
    [self.api callMethod:@"metaWeblog.newPost"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if ([responseObject respondsToSelector:@selector(numericValue)]) {
                         post.postID = [responseObject numericValue];
                         // TODO: fetch individual post
                         if (!post.date) {
                             // Set the temporary date until we get it from the server so it sorts properly on the list
                             post.date = [NSDate date];
                         }
                         if (success) {
                             success(post);
                         }
                     } else if (failure) {
                         NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid value returned for new post: %@", responseObject]};
                         NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
                         failure(error);
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
    NSParameterAssert(post.postID.integerValue > 0);
    NSParameterAssert(blog.username);
    NSParameterAssert(blog.password);
    
    if ([post.postID integerValue] <= 0) {
        if (failure) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Can't edit a post if it's not in the server"};
            NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        return;
    }

    NSDictionary *extraParameters = [self parametersWithRemotePost:post];
    NSArray *parameters = @[post.postID, blog.username, blog.password, extraParameters];
    
    [self.api callMethod:@"metaWeblog.editPost"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     // TODO: fetch individual post
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
    NSParameterAssert([post.postID longLongValue] > 0);
    NSNumber *postID = post.postID;
    if ([postID longLongValue] > 0) {
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:postID];
        [self.api callMethod:@"wp.deletePost"
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         if (success) success();
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (failure) failure(error);
                     }];
    }
}

- (void)restorePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)())success
           failure:(void (^)(NSError *))failure
{
    [self updatePost:post forBlog:blog success:success failure:failure];
}

#pragma mark - Private methods

- (NSArray *)remotePostsFromXMLRPCArray:(NSArray *)xmlrpcArray {
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:xmlrpcArray.count];
    for (NSDictionary *xmlrpcPost in xmlrpcArray) {
        [posts addObject:[self remotePostFromXMLRPCDictionary:xmlrpcPost]];
    }
    return [NSArray arrayWithArray:posts];
}

- (RemotePost *)remotePostFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary {
    RemotePost *post = [RemotePost new];

    post.postID = [xmlrpcDictionary numberForKey:@"post_id"];
    post.date = xmlrpcDictionary[@"post_date_gmt"];
    if (xmlrpcDictionary[@"link"]) {
        post.URL = [NSURL URLWithString:xmlrpcDictionary[@"link"]];
    }
    post.title = xmlrpcDictionary[@"post_title"];
    post.content = xmlrpcDictionary[@"post_content"];
    post.excerpt = xmlrpcDictionary[@"post_excerpt"];
    post.slug = xmlrpcDictionary[@"post_name"];
    post.status = xmlrpcDictionary[@"post_status"];
    post.password = xmlrpcDictionary[@"post_password"];
    if ([post.password isEmpty]) {
        post.password = nil;
    }
    post.parentID = [xmlrpcDictionary numberForKey:@"post_parent"];
    // When there is no featured image, post_thumbnail is an empty array :(
    NSDictionary *thumbnailDict = [xmlrpcDictionary dictionaryForKey:@"post_thumbnail"];
    post.postThumbnailID = [thumbnailDict numberForKey:@"attachment_id"];
    post.postThumbnailPath = [thumbnailDict stringForKey:@"link"];
    post.type = xmlrpcDictionary[@"post_type"];
    post.format = xmlrpcDictionary[@"post_format"];

    post.metadata = xmlrpcDictionary[@"custom_fields"];

    NSArray *terms = [xmlrpcDictionary arrayForKey:@"terms"];
    post.tags = [self tagsFromXMLRPCTermsArray:terms];
    post.categories = [self remoteCategoriesFromXMLRPCTermsArray:terms];

    return post;
}

- (NSArray *)tagsFromXMLRPCTermsArray:(NSArray *)terms {
    NSArray *tags = [terms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"taxonomy = 'post_tag' AND name != NIL"]];
    return [tags valueForKey:@"name"];
}

- (NSArray *)remoteCategoriesFromXMLRPCTermsArray:(NSArray *)terms {
    NSArray *categories = [terms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"taxonomy = 'category'"]];
    NSMutableArray *remoteCategories = [NSMutableArray arrayWithCapacity:categories.count];
    for (NSDictionary *category in categories) {
        [remoteCategories addObject:[self remoteCategoryFromXMLRPCDictionary:category]];
    }
    return [NSArray arrayWithArray:remoteCategories];
}

- (RemotePostCategory *)remoteCategoryFromXMLRPCDictionary:(NSDictionary *)xmlrpcCategory {
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = [xmlrpcCategory numberForKey:@"term_id"];
    category.name = [xmlrpcCategory stringForKey:@"name"];
    category.parentID = [xmlrpcCategory numberForKey:@"parent"];
    return category;
}

- (NSDictionary *)parametersWithRemotePost:(RemotePost *)post
{
    BOOL existingPost = ([post.postID longLongValue] > 0);
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];

    [postParams setValueIfNotNil:post.type forKey:@"post_type"];
    [postParams setValueIfNotNil:post.title forKey:@"title"];
    [postParams setValueIfNotNil:post.content forKey:@"description"];
    [postParams setValueIfNotNil:post.date forKey:@"date_created_gmt"];
    [postParams setValueIfNotNil:post.password forKey:@"wp_password"];
    [postParams setValueIfNotNil:[post.URL absoluteString] forKey:@"permalink"];
    [postParams setValueIfNotNil:post.excerpt forKey:@"mt_excerpt"];
    [postParams setValueIfNotNil:post.slug forKey:@"wp_slug"];
    
    // To remove a featured image, you have to send an empty string to the API
    if (post.postThumbnailID == nil) {
        // Including an empty string for wp_post_thumbnail generates
        // an "Invalid attachment ID" error in the call to wp.newPage
        if (existingPost) {
            postParams[@"wp_post_thumbnail"] = @"";
        }
    } else if (!existingPost || post.isFeaturedImageChanged) {
        // Do not add this param to existing posts when the featured image has not changed.
        // Doing so results in a XML-RPC fault: Invalid attachment ID.
        postParams[@"wp_post_thumbnail"] = post.postThumbnailID;
    }

    [postParams setValueIfNotNil:post.format forKey:@"wp_post_format"];
    [postParams setValueIfNotNil:[post.tags componentsJoinedByString:@","] forKey:@"mt_keywords"];

    if (existingPost && post.date == nil) {
        // Change the date of an already published post to the current date/time. (publish immediately)
        // Pass the current date so the post is updated correctly
        postParams[@"date_created_gmt"] = [NSDate date];
    }

    if (post.categories) {
        NSArray *categories = post.categories;
        NSMutableArray *categoryNames = [NSMutableArray arrayWithCapacity:[categories count]];
        for (RemotePostCategory *cat in categories) {
            [categoryNames addObject:cat.name];
        }
        
        postParams[@"categories"] = categoryNames;
    }

    if ([post.metadata count] > 0) {
        postParams[@"custom_fields"] = post.metadata;
    }

    if (post.status == nil) {
        post.status = @"publish";
    }

    if ([post.type isEqualToString:@"page"]) {
        [postParams setObject:post.status forKey:@"page_status"];
    }
    [postParams setObject:post.status forKey:@"post_status"];

    return [NSDictionary dictionaryWithDictionary:postParams];
}

@end
