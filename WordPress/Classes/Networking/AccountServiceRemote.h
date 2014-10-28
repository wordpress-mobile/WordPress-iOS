#import <Foundation/Foundation.h>

@protocol AccountServiceRemote <NSObject>

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;

@end
