#import <Foundation/Foundation.h>
#import "BlogServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

@interface BlogServiceRemoteREST : SiteServiceRemoteWordPressComREST <BlogServiceRemote>
@end
