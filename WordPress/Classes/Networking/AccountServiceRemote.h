#import <Foundation/Foundation.h>

@interface RemoteBlog : NSObject
@property NSNumber *ID;
@property (copy) NSString *title;
@property (copy) NSString *url;
@property (copy) NSString *xmlrpc;
@end

@protocol AccountServiceRemote <NSObject>

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;

@end
