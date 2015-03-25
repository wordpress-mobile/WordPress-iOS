#import <Foundation/Foundation.h>

@class Blog;

typedef void (^OptionsHandler)(NSDictionary *options);
typedef void (^PostFormatsHandler)(NSDictionary *postFormats);
typedef void (^MediaLibraryHandler)(NSArray *media);

@protocol BlogServiceRemote <NSObject>

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(OptionsHandler)success
                   failure:(void (^)(NSError *error))failure;

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(PostFormatsHandler)success
                       failure:(void (^)(NSError *error))failure;

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(MediaLibraryHandler)success
                        failure:(void (^)(NSError *error))failure;

@end
