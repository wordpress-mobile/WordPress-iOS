#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"
#import "ServiceRemoteXMLRPC.h"

@interface BlogServiceRemoteXMLRPC : NSObject<BlogServiceRemote, ServiceRemoteXMLRPC>
@end
