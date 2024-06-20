#import <Foundation/Foundation.h>
#import <WordPressKit/PostServiceRemote.h>
#import <WordPressKit/ServiceRemoteWordPressXMLRPC.h>

@interface PostServiceRemoteXMLRPC : ServiceRemoteWordPressXMLRPC <PostServiceRemote>

+ (RemotePost *)remotePostFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary;

@end
