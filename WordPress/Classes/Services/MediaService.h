#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalCoreDataService.h"

extern CGSize const MediaMaxImageSize;
extern NSInteger const MediaMinImageSizeDimension;
extern NSInteger const MediaMaxImageSizeDimension;

@class Media;
@class Blog;

@interface MediaService : NSObject <LocalCoreDataService>

+ (CGSize)maxImageSizeSetting;
+ (void)setMaxImageSizeSetting:(CGSize)imageSize;

- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion;
- (AFHTTPRequestOperation *)operationToUploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)getMediaWithID:(NSNumber *)mediaID inBlog:(Blog *)blog withSuccess:(void (^)(Media *media))success failure:(void (^)(NSError *error))failure;
- (void)uploadMedia:(Media *)media
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure;
- (Media *)findMediaWithID:(NSNumber *)mediaID inBlog:(Blog *)blog;

@end
