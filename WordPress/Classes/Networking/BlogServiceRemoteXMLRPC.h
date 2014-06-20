#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"

@class WPXMLRPCClient;

@interface BlogServiceRemoteXMLRPC : NSObject<BlogServiceRemote>

- (id)initWithApi:(WPXMLRPCClient *)api;

@end
