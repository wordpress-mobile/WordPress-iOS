#import "MediaService.h"
#import "Media.h"
#import "WordPress-Swift.h"

/**
 MediaService methods with the original implementation for exporting Media, while we feature-flag
 and transition to the new exporting support. Once transitioned, this category implementation could be removed.
 */
@interface MediaService (Legacy)

- (void)createMediaWith:(id<ExportableAsset>)asset
            forObjectID:(NSManagedObjectID *)objectID
              mediaName:(NSString *)mediaName
      thumbnailCallback:(void (^)(NSURL *thumbnailURL))thumbnailCallback
             completion:(void (^)(Media *media, NSError *error))completion;

- (void) createMediaForObjectID:(NSManagedObjectID *)objectID
                       mediaURL:(NSURL *)mediaURL
              mediaThumbnailURL:(NSURL *)mediaThumbnailURL
                      mediaType:(MediaType)mediaType
                      mediaSize:(CGSize)mediaSize
                          asset:(id <ExportableAsset>)asset
                     completion:(void (^)(Media *media, NSError *error))completion;

- (void)configureNewMedia:(Media *)media
             withMediaURL:(NSURL *)mediaURL
        mediaThumbnailURL:(NSURL *)mediaThumbnailURL
                mediaType:(MediaType)mediaType
                mediaSize:(CGSize)mediaSize
                    asset:(id <ExportableAsset>)asset;

- (void)imageForMedia:(Media *)mediaInRandomContext
                 size:(CGSize)requestSize
              success:(void (^)(UIImage *image))success
              failure:(void (^)(NSError *error))failure;

@end
