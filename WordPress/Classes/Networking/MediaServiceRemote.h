#import <Foundation/Foundation.h>

@class Blog;
@class RemoteMedia;

@protocol MediaServiceRemote <NSObject>

- (AFHTTPRequestOperation *)operationToUploadFile:(NSString *)path ofType:(NSString *)type withFilename:(NSString *)filename toBlog:(Blog *)blog success:(void (^)(NSNumber *mediaID, NSString *url))success failure:(void (^)(NSError *error))failure;

- (void) getMediaWithID:(NSNumber *) mediaID inBlog:(Blog *) blog withSuccess:(void (^)(RemoteMedia *remoteMedia))success failure:(void (^)(NSError *error))failure;
@end
