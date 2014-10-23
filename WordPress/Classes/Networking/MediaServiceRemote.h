#import <Foundation/Foundation.h>

@class Blog;
@class RemoteMedia;

@protocol MediaServiceRemote <NSObject>

- (AFHTTPRequestOperation *)operationToUploadFile:(NSString *)path
                                           ofType:(NSString *)type
                                     withFilename:(NSString *)filename
                                           toBlog:(Blog *)blog
                                          success:(void (^)(NSNumber *mediaID, NSString *url))success
                                          failure:(void (^)(NSError *error))failure;

- (void) getMediaWithID:(NSNumber *) mediaID
                 forBlog:(Blog *)blog
                 success:(void (^)(RemoteMedia *remoteMedia))success
                 failure:(void (^)(NSError *error))failure;

- (void) createMedia:(RemoteMedia *)media
                forBlog:(Blog *)blog
                success:(void (^)(RemoteMedia *remoteMedia))success
                failure:(void (^)(NSError *error))failure;

@end
