#import <Foundation/Foundation.h>
#import "PostStatusServiceRemote.h"
#import "ServiceRemoteXMLRPC.h"

@class Blog;
@class RemotePostStatus;

@interface PostStatusServiceRemoteXMLRPC : NSObject <PostStatusServiceRemote, ServiceRemoteXMLRPC>

@end