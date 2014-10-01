#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface BlogServiceRemoteREST : NSObject<BlogServiceRemote, ServiceRemoteREST>
@end
