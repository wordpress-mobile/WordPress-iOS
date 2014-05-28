#import <Foundation/Foundation.h>

@class Blog;

@protocol MediaServiceRemote <NSObject>

- (AFHTTPRequestOperation *)operationToUploadFile:(NSString *)path ofType:(NSString *)type withFilename:(NSString *)filename toBlog:(Blog *)blog success:(void (^)(NSNumber *mediaID, NSString *url))success failure:(void (^)(NSError *error))failure;

@end
