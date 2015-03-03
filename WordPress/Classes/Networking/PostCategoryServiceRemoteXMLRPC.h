#import <Foundation/Foundation.h>
#import "PostCategoryServiceRemote.h"
#import "ServiceRemoteXMLRPC.h"

@class Blog;
@class RemoteCategory;

@interface PostCategoryServiceRemoteXMLRPC : NSObject<PostCategoryServiceRemote, ServiceRemoteXMLRPC>

@end
