#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalCoreDataService.h"

extern CGSize const MediaMaxImageSize;
extern NSInteger const MediaMinImageSizeDimension;
extern NSInteger const MediaMaxImageSizeDimension;

@class Media;

@interface MediaService : NSObject <LocalCoreDataService>

+ (CGSize)maxImageSizeSetting;
+ (void)setMaxImageSizeSetting:(CGSize)imageSize;

- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion;
- (AFHTTPRequestOperation *)operationToUploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
