#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalCoreDataService.h"

@class Media;

@interface MediaService : NSObject <LocalCoreDataService>

- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion;

/** Creates a Media object based on the asset provided and associated to the post object.
 
 @param asset the asset to be used on the media object
 @param postObjectID the post where the media will be associated
 @param completion a block to where Media object will be returned on success.
 */
- (void)createVideoMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *) postObjectID completion:(void (^)(Media *media))completion;

- (AFHTTPRequestOperation *)operationToUploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
@end
