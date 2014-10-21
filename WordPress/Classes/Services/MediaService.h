#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalCoreDataService.h"

@class Media;
@class Blog;

@interface MediaService : NSObject <LocalCoreDataService>

- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion;
- (AFHTTPRequestOperation *)operationToUploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void) getMediaWithID:(NSNumber *)mediaID inBlog:(Blog *)blog withSuccess:(void (^)(Media *media))success failure:(void (^)(NSError *error))failure;

@end
