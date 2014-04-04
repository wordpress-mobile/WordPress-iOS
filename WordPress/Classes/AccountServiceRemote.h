#import <Foundation/Foundation.h>

@class WordPressXMLRPCApi;

@interface AccountServiceRemote : NSObject

- (id)initWithRemoteApi:(WordPressXMLRPCApi *)api;

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;

@end
