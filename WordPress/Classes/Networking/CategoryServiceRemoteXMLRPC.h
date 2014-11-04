#import <Foundation/Foundation.h>
#import "CategoryServiceRemote.h"
#import "ServiceRemoteXMLRPC.h"

@class Blog;
@class RemoteCategory;

@interface CategoryServiceRemoteXMLRPC : NSObject<CategoryServiceRemote, ServiceRemoteXMLRPC>

@end
