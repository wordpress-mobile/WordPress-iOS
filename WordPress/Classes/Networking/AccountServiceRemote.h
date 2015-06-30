#import <Foundation/Foundation.h>
#import "RemoteUser.h"

@class WPAccount;

@protocol AccountServiceRemote <NSObject>

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;
- (void)getDetailsForAccount:(WPAccount *)account success:(void (^)(RemoteUser *remoteUser))success failure:(void (^)(NSError *error))failure;

@end
