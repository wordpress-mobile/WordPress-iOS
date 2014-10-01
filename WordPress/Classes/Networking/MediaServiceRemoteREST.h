#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface MediaServiceRemoteREST : NSObject <MediaServiceRemote, ServiceRemoteREST>
@end
