#import "BlogServiceRemoteXMLRPC.h"
#import <WordPressApi.h>
#import "Blog.h"

@interface BlogServiceRemoteXMLRPC ()

@property (nonatomic, strong) WPXMLRPCClient *api;

@end

@implementation BlogServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}


- (void)syncPostsAndMetadataForBlog:(Blog *)blog
                  categoriesSuccess:(CategoriesHandler)categoriesSuccess
                     optionsSuccess:(OptionsHandler)optionsSuccess
                 postFormatsSuccess:(PostFormatsHandler)postFormatsSuccess
                       postsSuccess:(PostsHandler)postsSuccess
                     overallSuccess:(void (^)(void))overallSuccess
                            failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:4];
    operation = [self operationForOptionsWithBlog:blog success:optionsSuccess failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithBlog:blog success:postFormatsSuccess failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithBlog:blog success:categoriesSuccess failure:nil];
    [operations addObject:operation];

    // TODO :: Replace this if with a check for nil postsSuccess & do the conditional in the layer up from remote
    if (!blog.isSyncingPosts) {
        operation = [self operationForPostsWithBlog:blog batchSize:40 loadMore:NO success:postsSuccess failure:nil];
        [operations addObject:operation];
        blog.isSyncingPosts = YES;
    }

    AFHTTPRequestOperation *combinedOperation = [blog.api combinedHTTPRequestOperationWithOperations:operations success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (overallSuccess) {
            overallSuccess();
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [self.api enqueueHTTPRequestOperation:combinedOperation];
}

- (void)syncPostsForBlog:(Blog *)blog batchSize:(NSUInteger)batchSize loadMore:(BOOL)more success:(PostsHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForPostsWithBlog:blog batchSize:batchSize loadMore:more success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}


- (void)syncPagesForBlog:(Blog *)blog batchSize:(NSUInteger)batchSize loadMore:(BOOL)more success:(PagesHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForPagesWithBlog:blog batchSize:batchSize loadMore:more success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}



- (void)syncCategoriesForBlog:(Blog *)blog success:(CategoriesHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForCategoriesWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}



- (void)syncOptionsForBlog:(Blog *)blog success:(OptionsHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForOptionsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}



- (void)syncMediaLibraryForBlog:(Blog *)blog success:(MediaHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForMediaLibraryWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}



- (void)syncPostFormatsForBlog:(Blog *)blog success:(PostFormatsHandler)success failure:(void (^)(NSError *))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForPostFormatsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}


- (void)syncBlogContentAndMetadata:(Blog *)blog
                 categoriesSuccess:(CategoriesHandler)categoriesSuccess
                      mediaSuccess:(MediaHandler)mediaSuccess
                    optionsSuccess:(OptionsHandler)optionsSuccess
                      pagesSuccess:(PagesHandler)pagesSuccess
                postFormatsSuccess:(PostFormatsHandler)postFormatsSuccess
                      postsSuccess:(PostsHandler)postsSuccess
                    overallSuccess:(void (^)(void))overallSuccess
                           failure:(void (^)(NSError *error))failure
{

    WPXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:6];
    operation = [self operationForOptionsWithBlog:blog success:optionsSuccess failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithBlog:blog success:postFormatsSuccess failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithBlog:blog success:categoriesSuccess failure:nil];
    [operations addObject:operation];

    if (!blog.isSyncingPosts) {
        operation = [self operationForPostsWithBlog:blog batchSize:40 loadMore:NO success:postsSuccess failure:nil];
        [operations addObject:operation];
        blog.isSyncingPosts = YES;
    }

    if (!blog.isSyncingPages) {
        // TODO :: Make batch size a parameter
        operation = [self operationForPagesWithBlog:blog batchSize:40 loadMore:NO success:pagesSuccess failure:nil];
        [operations addObject:operation];
        blog.isSyncingPages = YES;
    }

    if (!blog.isSyncingMedia) {
        operation = [self operationForMediaLibraryWithBlog:blog success:mediaSuccess failure:nil];
        [operations addObject:operation];
        blog.isSyncingMedia = YES;
    }

    AFHTTPRequestOperation *combinedOperation = [blog.api combinedHTTPRequestOperationWithOperations:operations success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"syncBlogWithSuccess:failure: completed successfully.");
        if (overallSuccess) {
            overallSuccess();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"syncBlogWithSuccess:failure: encountered an error: %@", error);

        if (failure) {
            failure(error);
        }
    }];

    [blog.api enqueueHTTPRequestOperation:combinedOperation];


}

- (WPXMLRPCRequestOperation *)operationForOptionsWithBlog:(Blog *)blog success:(OptionsHandler)success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getOptions" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");

        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing options: %@", error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostFormatsWithBlog:(Blog *)blog success:(PostFormatsHandler)success failure:(void (^)(NSError *error))failure {
    NSDictionary *dict = [NSDictionary dictionaryWithObject:@"1" forKey:@"show-supported"];
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:dict];

    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPostFormats" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");

        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing post formats (%@): %@", operation.request.URL, error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCategoriesWithBlog:(Blog *)blog success:(CategoriesHandler)success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getCategories" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");

        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing categories (%@): %@", operation.request.URL, error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostsWithBlog:(Blog *)blog batchSize:(NSUInteger)batchSize loadMore:(BOOL)more success:(PostsHandler)success failure:(void (^)(NSError *error))failure {
    // Don't load more than 20 posts if we aren't at the end of the table,
    // even if they were previously donwloaded
    //
    // Blogs with long history can get really slow really fast,
    // with no chance to go back

    NSArray *parameters = [blog getXMLRPCArgsWithExtra:[NSNumber numberWithUnsignedInteger:batchSize]];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"metaWeblog.getRecentPosts" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");

        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing posts (%@): %@", operation.request.URL, error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPagesWithBlog:(Blog *)blog batchSize:(NSUInteger)batchSize loadMore:(BOOL)more success:(PagesHandler)success failure:(void (^)(NSError *error))failure {
    // Don't load more than 20 pages if we aren't at the end of the table,
    // even if they were previously donwloaded
    //
    // Blogs with long history can get really slow really fast,
    // with no chance to go back

    NSArray *parameters = [blog getXMLRPCArgsWithExtra:[NSNumber numberWithUnsignedInteger:batchSize]];
    WPXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPages" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");

        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing pages (%@): %@", operation.request.URL, error);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}


- (WPXMLRPCRequestOperation *)operationForMediaLibraryWithBlog:(Blog *)blog success:(MediaHandler)success failure:(void (^)(NSError *))failure {
    WPXMLRPCRequest *mediaLibraryRequest = [self.api XMLRPCRequestWithMethod:@"wp.getMediaLibrary" parameters:[blog getXMLRPCArgsWithExtra:nil]];
    WPXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:mediaLibraryRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");

        if (success) {
            success(responseObject);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing media library: %@", [error localizedDescription]);

        if (failure) {
            failure(error);
        }
    }];
    return operation;
}


@end
