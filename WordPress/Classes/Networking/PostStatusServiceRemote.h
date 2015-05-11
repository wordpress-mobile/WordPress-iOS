#import <Foundation/Foundation.h>

@class Blog, RemotePostStatus;

@protocol PostStatusServiceRemote <NSObject>

- (void)getStatusesForBlog:(Blog *)blog
                     success:(void (^)(NSArray *statuses))success
                     failure:(void (^)(NSError *error))failure;

- (NSDictionary *)simulatedRemotePostStatusResponseObject;

@end
