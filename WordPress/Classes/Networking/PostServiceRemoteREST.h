#import <Foundation/Foundation.h>
#import "PostServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface PostServiceRemoteREST : NSObject<PostServiceRemote, ServiceRemoteREST>

@end
