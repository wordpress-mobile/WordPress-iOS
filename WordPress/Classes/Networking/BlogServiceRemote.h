#import <Foundation/Foundation.h>

@class Blog;

typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^MultiAuthorCheckHandler)(BOOL isMultiAuthor);

@protocol BlogServiceRemote <NSObject>

- (void)checkMultiAuthorForBlog:(Blog *)blog
                        success:(MultiAuthorCheckHandler)success
                        failure:(void (^)(NSError *error))failure;

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *error))failure;

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *error))failure;

@end
