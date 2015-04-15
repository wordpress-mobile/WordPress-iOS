#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, PostStatus;

@interface PostStatusService : NSObject <LocalCoreDataService>

- (void)syncStatusesForBlog:(Blog *)blog
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

@end
