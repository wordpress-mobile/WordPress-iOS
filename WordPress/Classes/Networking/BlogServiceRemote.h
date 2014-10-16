#import <Foundation/Foundation.h>

@class Blog;

typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^CategoriesHandler)(NSArray *categories);
typedef void (^PostsHandler)(NSArray *posts);
typedef void (^PagesHandler)(NSArray *pages);

@protocol BlogServiceRemote <NSObject>

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *error))failure;

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *error))failure;

- (void)syncBlogMetadata:(Blog *)blog
          optionsSuccess:(OptionsHandler)optionsSuccess
      postFormatsSuccess:(PostFormatsHandler)postFormatsSuccess
          overallSuccess:(void (^)(void))overallSuccess
                 failure:(void (^)(NSError *error))failure;


@end
