#import <Foundation/Foundation.h>
#import "CategoryServiceRemote.h"
#import "ServiceRemoteXMLRPC.h"

@class Blog, RemoteCategory;

@interface CategoryServiceRemoteXMLRPC : NSObject<CategoryServiceRemote, ServiceRemoteXMLRPC>

@end
