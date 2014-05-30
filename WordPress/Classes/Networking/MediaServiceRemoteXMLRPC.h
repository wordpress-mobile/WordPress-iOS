#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"

@class WPXMLRPCClient;

@interface MediaServiceRemoteXMLRPC : NSObject <MediaServiceRemote>
- (id)initWithApi:(WPXMLRPCClient *)api;
@end
