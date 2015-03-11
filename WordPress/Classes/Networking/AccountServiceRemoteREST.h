#import <Foundation/Foundation.h>
#import "AccountServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface AccountServiceRemoteREST : NSObject <AccountServiceRemote, ServiceRemoteREST>

- (void)getDetailsWithSuccess:(void (^)(NSDictionary *userDetails))success failure:(void (^)(NSError *error))failure;

@end
