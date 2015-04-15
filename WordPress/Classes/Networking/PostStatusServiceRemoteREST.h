#import <Foundation/Foundation.h>
#import "PostStatusServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface PostStatusServiceRemoteREST : NSObject <PostStatusServiceRemote, ServiceRemoteREST>

@end