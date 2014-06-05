#import <Foundation/Foundation.h>
#import "AccountServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface AccountServiceRemoteREST : NSObject <AccountServiceRemote, ServiceRemoteREST>
@end
