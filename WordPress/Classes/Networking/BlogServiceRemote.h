#import <Foundation/Foundation.h>

@class Blog, WPXMLRPCClient;

typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^CommentsHandler)(NSArray *comments);
typedef void (^CategoriesHandler)(NSArray *categories);
typedef void (^PostsHandler)(NSArray *posts);
typedef void (^PagesHandler)(NSArray *pages);
typedef void (^MediaHandler)(NSArray *media);

@interface BlogServiceRemote : NSObject

- (id)initWithRemoteApi:(WPXMLRPCClient *)api;

- (void)syncPostsAndMetadataForBlog:(Blog *)blog
                  categoriesSuccess:(CategoriesHandler)categoriesSuccess
                     optionsSuccess:(OptionsHandler)optionsSuccess
                 postFormatsSuccess:(PostFormatsHandler)postFormatsSuccess
                       postsSuccess:(PostsHandler)postsSuccess
                     overallSuccess:(void (^)(void))overallSuccess
                            failure:(void (^)(NSError *error))failure;

- (void)syncPostsForBlog:(Blog *)blog
               batchSize:(NSUInteger)batchSize
                loadMore:(BOOL)more
                 success:(PostsHandler)success
                 failure:(void (^)(NSError *error))failure;

- (void)syncPagesForBlog:(Blog *)blog
               batchSize:(NSUInteger)batchSize
                loadMore:(BOOL)more
                 success:(PagesHandler)success
                 failure:(void (^)(NSError *error))failure;

- (void)syncCategoriesForBlog:(Blog *)blog
                      success:(CategoriesHandler)success
                      failure:(void (^)(NSError *error))failure;

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *error))failure;

- (void)syncCommentsForBlog:(Blog *)blog
                    success:(CommentsHandler)success
                    failure:(void (^)(NSError *error))failure;

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(MediaHandler)success
                        failure:(void (^)(NSError *error))failure;

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *error))failure;

- (void)syncBlogContentAndMetadata:(Blog *)blog
                 categoriesSuccess:(CategoriesHandler)categoriesSuccess
                   commentsSuccess:(CommentsHandler)commentsSuccess
                      mediaSuccess:(MediaHandler)mediaSuccess
                    optionsSuccess:(OptionsHandler)optionsSuccess
                      pagesSuccess:(PagesHandler)pagesSuccess
                postFormatsSuccess:(PostFormatsHandler)postFormatsSuccess
                      postsSuccess:(PostsHandler)postsSuccess
                    overallSuccess:(void (^)(void))overallSuccess
                           failure:(void (^)(NSError *error))failure;


@end
