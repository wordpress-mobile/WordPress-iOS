#import "PostServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "BasePost.h"
#import "DisplayableImageHelper.h"
#import "RemotePost.h"
#import "RemotePostCategory.h"
#import "NSMutableDictionary+Helpers.h"
#import <WordPressApi/WordPressApi.h>

const NSInteger HTTP404ErrorCode = 404;

static NSString * const RemoteOptionKeyNumber = @"number";
static NSString * const RemoteOptionKeyOffset = @"offset";
static NSString * const RemoteOptionKeyOrder = @"order";
static NSString * const RemoteOptionKeyOrderBy = @"orderby";
static NSString * const RemoteOptionKeyStatus = @"post_status";

static NSString * const RemoteOptionValueOrderAscending = @"ASC";
static NSString * const RemoteOptionValueOrderDescending = @"DESC";
static NSString * const RemoteOptionValueOrderByDate = @"date";
static NSString * const RemoteOptionValueOrderByModified = @"modified";
static NSString * const RemoteOptionValueOrderByTitle = @"title";
static NSString * const RemoteOptionValueOrderByCommentCount = @"comment_count";
static NSString * const RemoteOptionValueOrderByPostID = @"ID";

@implementation PostServiceRemoteXMLRPC

- (void)getPostWithID:(NSNumber *)postID
              success:(void (^)(RemotePost *post))success
              failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:postID];
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
               success:(void (^)(NSArray <RemotePost *> *remotePosts))success
               failure:(void (^)(NSError *))failure {
    [self getPostsOfType:postType options:nil success:success failure:failure];
}

- (void)getPostsOfType:(NSString *)postType
               options:(NSDictionary *)options
               success:(void (^)(NSArray <RemotePost *> *remotePosts))success
               failure:(void (^)(NSError *error))failure {
    NSArray *statuses = @[PostStatusDraft, PostStatusPending, PostStatusPrivate, PostStatusPublish, PostStatusScheduled, PostStatusTrash];
    NSString *postStatus = [statuses componentsJoinedByString:@","];
    NSDictionary *extraParameters = @{
                                      @"number": @40,
                                      @"post_type": postType,
                                      @"post_status": postStatus,
                                      };
    if (options) {
        NSMutableDictionary *mutableParameters = [extraParameters mutableCopy];
        [mutableParameters addEntriesFromDictionary:options];
        extraParameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    }
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];
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
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure
{
    NSDictionary *extraParameters = [self parametersWithRemotePost:post];
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:extraParameters];
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
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure
{
    NSParameterAssert(post.postID.integerValue > 0);
    
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
    NSMutableArray *parameters = [NSMutableArray arrayWithArray:[self XMLRPCArgumentsWithExtra:extraParameters]];
    [parameters replaceObjectAtIndex:0 withObject:post.postID];
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
           success:(void (^)())success
           failure:(void (^)(NSError *))failure
{
    NSParameterAssert([post.postID longLongValue] > 0);
    NSNumber *postID = post.postID;
    if ([postID longLongValue] > 0) {
        NSArray *parameters = [self XMLRPCArgumentsWithExtra:postID];
        [self.api callMethod:@"wp.deletePost"
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         if (success) success();
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (failure) failure(error);
                     }];
    }
}

- (void)trashPost:(RemotePost *)post
          success:(void (^)(RemotePost *))success
          failure:(void (^)(NSError *))failure
{
    NSParameterAssert([post.postID longLongValue] > 0);
    NSNumber *postID = post.postID;
    if ([postID longLongValue] > 0) {
        NSArray *parameters = [self XMLRPCArgumentsWithExtra:postID];

        WPXMLRPCRequest *deletePostRequest = [self.api XMLRPCRequestWithMethod:@"wp.deletePost" parameters:parameters];
        WPXMLRPCRequestOperation *delOperation = [self.api XMLRPCRequestOperationWithRequest:deletePostRequest success:nil failure:nil];

        WPXMLRPCRequest *getPostRequest = [self.api XMLRPCRequestWithMethod:@"wp.getPost" parameters:parameters];
        WPXMLRPCRequestOperation *getOperation = [self.api XMLRPCRequestOperationWithRequest:getPostRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                // The post was trashed but not yet deleted.
                RemotePost *post = [self remotePostFromXMLRPCDictionary:responseObject];
                success(post);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error.code == HTTP404ErrorCode) {
                // The post was deleted.
                if (success) {
                    success(post);
                }
            }
        }];

        AFHTTPRequestOperation *operation = [self.api combinedHTTPRequestOperationWithOperations:@[delOperation, getOperation]
                                                                                         success:nil
                                                                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                                             if (failure) {
                                                                                                 failure(error);
                                                                                             }
                                                                                         }];
        [self.api enqueueHTTPRequestOperation:operation];
    }
}

- (void)restorePost:(RemotePost *)post
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *error))failure
{
    [self updatePost:post success:success failure:failure];
}

- (NSDictionary *)dictionaryWithRemoteOptions:(id <PostServiceRemoteOptions>)options
{
    NSMutableDictionary *remoteParams = [NSMutableDictionary dictionary];
    if (options.number) {
        [remoteParams setObject:options.number forKey:RemoteOptionKeyNumber];
    }
    if (options.offset) {
        [remoteParams setObject:options.offset forKey:RemoteOptionKeyOffset];
    }
    
    NSString *statusesStr = nil;
    if (options.statuses.count) {
        statusesStr = [options.statuses componentsJoinedByString:@","];
    }
    if (options.order) {
        NSString *orderStr = nil;
        switch (options.order) {
            case PostServiceResultsOrderDescending:
                orderStr = RemoteOptionValueOrderDescending;
                break;
            case PostServiceResultsOrderAscending:
                orderStr = RemoteOptionValueOrderAscending;
                break;
        }
        [remoteParams setObject:orderStr forKey:RemoteOptionKeyOrder];
    }
    
    NSString *orderByStr = nil;
    if (options.orderBy) {
        switch (options.orderBy) {
            case PostServiceResultsOrderingByDate:
                orderByStr = RemoteOptionValueOrderByDate;
                break;
            case PostServiceResultsOrderingByModified:
                orderByStr = RemoteOptionValueOrderByModified;
                break;
            case PostServiceResultsOrderingByTitle:
                orderByStr = RemoteOptionValueOrderByTitle;
                break;
            case PostServiceResultsOrderingByCommentCount:
                orderByStr = RemoteOptionValueOrderByCommentCount;
                break;
            case PostServiceResultsOrderingByPostID:
                orderByStr = RemoteOptionValueOrderByPostID;
                break;
        }
    }
    
    if (statusesStr.length) {
        [remoteParams setObject:statusesStr forKey:RemoteOptionKeyStatus];
    }
    if (orderByStr.length) {
        [remoteParams setObject:orderByStr forKey:RemoteOptionKeyOrderBy];
    }
    
    return remoteParams.count ? [NSDictionary dictionaryWithDictionary:remoteParams] : nil;
}

#pragma mark - Private methods

- (NSArray <RemotePost *> *)remotePostsFromXMLRPCArray:(NSArray *)xmlrpcArray {
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcPost) {
        return [self remotePostFromXMLRPCDictionary:xmlrpcPost];
    }];
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
    post.authorID = [xmlrpcDictionary numberForKey:@"post_author"];
    post.status = [self statusForPostStatus:xmlrpcDictionary[@"post_status"] andDate:post.date];
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

    // Pick an image to use for display
    if (post.postThumbnailPath) {
        post.pathForDisplayImage = post.postThumbnailPath;
    } else {
        // parse content for a suitable image.
        post.pathForDisplayImage = [DisplayableImageHelper searchPostContentForImageToDisplay:post.content];
    }

    return post;
}

- (NSString *)statusForPostStatus:(NSString *)status andDate:(NSDate *)date
{
    // Scheduled posts are synced with a post_status of 'publish' but we want to
    // work with a status of 'future' from within the app.
    if (date == [date laterDate:[NSDate date]]) {
        return PostStatusScheduled;
    }
    return status;
}

- (NSArray *)tagsFromXMLRPCTermsArray:(NSArray *)terms {
    NSArray *tags = [terms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"taxonomy = 'post_tag' AND name != NIL"]];
    return [tags valueForKey:@"name"];
}

- (NSArray *)remoteCategoriesFromXMLRPCTermsArray:(NSArray *)terms {
    return [[terms wp_filter:^BOOL(NSDictionary *category) {
        return [[category stringForKey:@"taxonomy"] isEqualToString:@"category"];
    }] wp_map:^id(NSDictionary *category) {
        return [self remoteCategoryFromXMLRPCDictionary:category];
    }];
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
        NSArray *categoryNames = [post.categories wp_map:^id(RemotePostCategory *category) {
            return category.name;
        }];
        
        postParams[@"categories"] = categoryNames;
    }

    if ([post.metadata count] > 0) {
        postParams[@"custom_fields"] = post.metadata;
    }

    // Scheduled posts need to sync with a status of 'publish'.
    // Passing a status of 'future' will set the post status to 'draft'
    // This is an apparent inconsistency in the XML-RPC API as 'future' should
    // be a valid status.
    // https://codex.wordpress.org/Post_Status_Transitions
    if (post.status == nil || [post.status isEqualToString:PostStatusScheduled]) {
        post.status = PostStatusPublish;
    }

    if ([post.type isEqualToString:@"page"]) {
        [postParams setObject:post.status forKey:@"page_status"];
    }
    [postParams setObject:post.status forKey:@"post_status"];

    return [NSDictionary dictionaryWithDictionary:postParams];
}

@end
