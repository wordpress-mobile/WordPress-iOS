#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalService.h"

@class Media;

@interface MediaService : NSObject <LocalService>
- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion;
- (AFHTTPRequestOperation *)uploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
@end
