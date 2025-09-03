#import <Foundation/Foundation.h>
#import "PostServiceRemote.h"
#import "ServiceRemoteWordPressXMLRPC.h"

@interface PostServiceRemoteXMLRPC : ServiceRemoteWordPressXMLRPC <PostServiceRemote>

+ (RemotePost *)remotePostFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary;

@end
