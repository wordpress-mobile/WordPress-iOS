#import <Foundation/Foundation.h>
#import "CommentServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface CommentServiceRemoteREST : NSObject <CommentServiceRemote, ServiceRemoteREST>
@end
